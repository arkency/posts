---
created_at: 2022-02-23 11:15:15 +0100
author: Szymon Fiedler
tags: ["heroku", "rails", "assets", "sprockets"]
publish: true
---
# Don't waste your time on assets compilation on Heroku

At some point, you may want or be forced to use the CDN to serve assets of your Rails app. When your app is globally available, you may want to serve the assets from strategically located servers around the world to provide the best possible experience for the end user. Serving static assets via Puma is not the best idea — it'll be slow. The only viable option on Heroku is to use CDN. I will show you how to do it smart, save time and have faster deployments

<!-- more -->

## Difference between Push and Pull CDN
There are two types of CDNs. _Push_ and _Pull_. _Push_ approach which basically acts as like the origin server. Assets are requested for client directly from it. The only downside is that we need to deliver the assets to CDN on our own, but it's not that hard as it sounds. If we used the _Pull_ CDN, it would do it for us, but initial request for a user would be sluggish and rewriting URLs is a no–go. Btw. [Amazon found every 100ms of latency cost them 1% in sales](https://www.gigaspaces.com/blog/amazon-found-every-100ms-of-latency-cost-them-1-in-sales) — big money on the table.

## Existing solutions for pushing assets to CDN
There are quite few solutions available, the most popular is probably `asset_sync` gem. Basically, it hooks into `assets:precompile` and syncs assets with given S3 bucket (or other provider). I don't like implicit hooks. It also happens during deployment adding more time to it. On Heroku, all the assets and their sources, like "beloved" `node_modules` contribute to slug size. It's easy to be far away from their soft—limit (300MB) which contributes to slower deployments because of longer compression time.

## Our way
What if I tell you that assets can be compiled on CI, in parallel with the test suite and pushed to CDN, so they're instantly available as soon as the app is released?

How it started: >8 minutes from push to master to release

How is it going: ~2 minutes from push to master to release


### The process
- assets are precompiled using pretty modern stack on CI in parallel while the tests are running,
- CI uploads them to CDN's bucket along with manifest file,
- custom Heroku buildpack downloads manifest,
- during build phase, asset precompilation is skipped since manifest is in place,
- app is released and links assets from CDN,
- build time and slug size are saved

### bin/rails assets:precompile in a modern way
Our current stack is sprockets with [esbuild](https://esbuild.github.io), [cssbundling-rails](https://github.com/rails/cssbundling-rails), [tailwind](https://tailwindcss.com) along with [postcss](https://postcss.org) and [cssnano](https://cssnano.co).

One day we'll switch to [Propshaft](https://github.com/rails/propshaft), all the preceding steps makes us closer to it.

We went with _CloudFront_, producing gzipped versions of assets is obsolete since the CDN can do it on our behalf. It'll even pick the best compression algorithm for client's browser like [_brotli_](https://github.com/google/brotli) instead of good 'ol _gzip_.

```ruby
# config/environments/production.rb
config.asset_host = ENV.fetch("ASSET_HOST")
config.assets.compile = false
config.assets.gzip = false
```

We build the assets as a separate workflow on Github actions

```yaml
# .github/workflows/assets.yml
name: CDN assets

on:
  workflow_dispatch:
  push:
    branches:
      - master

env:
  RAILS_ENV: test
  RAILS_MASTER_KEY: ${{ secrets.RAILS_TEST_MASTER_KEY }}

jobs:
  assets:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1.0
          bundler-cache: true

      - name: Setup Node
        uses: actions/setup-node@v2
        with:
          node-version: 16.x
          cache: "npm"

      - name: Install dependencies
        run: |
          npm install --no-fund --no-audit

      - name: Build assets
        env:
          ASSET_ENV: production
          GIT_COMMIT: ${{ github.sha }}
        run: |
          bin/rails assets:precompile
```
 
As you can see, we use limited number of `ENV` variables here, we replaced `RAILS_ENV=production` with `ASSET_ENV=production` for `assets:precompile`. It required simple tweaks in esbuild's and postcss's configs. Since we don't do minification with Sprockets, we don't need the full Rails env here. It happens within seconds now.

### Uploading the files

```ruby
# lib/cdn_assets.rb
require "aws-sdk-s3"

class CdnAssets
  def initialize(
    pool: Concurrent::FixedThreadPool.new(10),
    root: Rails.root,
    client: Aws::S3::Client.new(
      {
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        region: ENV["AWS_REGION"],
      },
    ),
    mk_manifest_path: -> { Sprockets::Railtie.build_manifest(Rails.application).path },
    mk_commit_sha: -> { ENV.fetch("GIT_COMMIT") { `git rev-parse --verify HEAD`.strip } }
  )
    @pool = pool
    @root = root
    @client = client
    @mk_manifest_path = mk_manifest_path
    @mk_commit_sha = mk_commit_sha
  end

  def upload(commit_sha = mk_commit_sha.())
    _synced_files = synced_files

    puts "Uploading #{_synced_files.size} missing files"

    _synced_files.each do |path, _|
      pool.post do
        content_type = detect_content_type(path)
        params = { bucket: bucket, key: path, body: body(path), acl: acl }
        params[:content_type] = content_type if content_type
        client.put_object(params)

        puts path
      end
    end

    puts "Uploading manifest files"

    [manifest_of(commit_sha), latest_manifest].each do |destination_manifest_path|
      client.put_object(
        bucket: bucket,
        key: destination_manifest_path,
        body: File.read(mk_manifest_path.()),
        acl: acl,
        content_type: "application/json",
      )
      puts destination_manifest_path
    end

    pool.shutdown
    pool.wait_for_termination
  end

  private

  attr_reader :pool, :root, :client, :mk_manifest_path, :mk_commit_sha

  def manifest_of(commit_sha)
    "assets/manifest-#{commit_sha}.json"
  end

  def latest_manifest
    "assets/manifest-latest.json"
  end

  def detect_content_type(path)
    MIME::Types.type_for(path).first&.content_type
  end

  def body(path)
    Pathname.new(prefix).join(path).read
  end

  def synced_files
    local_files - remote_files
  end

  def local_files
    Dir
      .chdir(root.join(prefix)) { Dir.glob("**/*").reject { |path| File.directory?(path) } }
      .map { |relative_path| [relative_path, digest_for(relative_path)] }
  end

  def digest_for(relative_path)
    Digest::MD5.hexdigest(body(relative_path))
  end

  def remote_files
    client
      .list_objects(bucket: bucket)
      .flat_map { |response| response.contents.map { |file| [file.key, normalize_etag(file.etag)] } }
  end

  def normalize_etag(etag)
    etag.delete_prefix("\"").delete_suffix("\"")
  end

  def bucket
    ENV["AWS_BUCKET"]
  end

  def acl
    "public-read"
  end

  def prefix
    "public"
  end
end
```

We used [FixedThreadPool](https://ruby-concurrency.github.io/concurrent-ruby/master/file.thread_pools.html#FixedThreadPool) to upload files in parallel. _Concurrent Ruby_ is a great library to do this, for sure it's already present in your codebase since it's a dependency for ActiveSupport, [dry-rb](https://dry-rb.org) or one and only [RailsEventStore](https://railseventstore.org).

Important optimisation is listing files present in the bucket along with their _ETags_, we can compare those with the ones to be sent and only upload files which name or content differs. It's especially important to compare not only name for non–digested files. We upload everything from Rails `public` directory, eg. `422.html` — no digest here, file could change and it would be omitted during upload while relying on its path only (or _key_ when using S3 vocabulary). _S3_ can produce _ETag_ in few ways, check which applies to your scenario in the [documentation](https://docs.aws.amazon.com/AmazonS3/latest/API/API_Object.html). For our case it's `Digest::MD5.hexdigest` of a file content.

Telling S3 what is the `Content-Type` of uploaded files is a must. If it's not provided, it'll do a best guess. However, browser won't run `application.js` with `Content-Type: binary/octet`. Guessing the content type is not where it shines unfortunately.

Rails expect that `.sprockets-manifest-totallyrandomdigest.json` will be present in `public/assets` when the app starts. Yep, digest included in manifest filename is totally random and Rails detects it based on path and regex matching the name. We use same mechanism to find desired file: [Sprockets::Railtie.build_manifest(Rails.application).path](https://github.com/rails/sprockets-rails/blob/5badf679b206e4f218b9e3a42730d27779e572b2/lib/sprockets/railtie.rb#L213-L217). After that we're able to upload it under a known and predictable name: `manifest-$COMMIT_SHA.json`. We produce `manifest-latest.json` as a fallback in case something went wrong and we haven't delivered manifest referencing released commit.

Rake task for the ease of use:

```ruby
# lib/tasks/cdn_assets.rake
namespace :cdn_assets do
  desc "Distribute public/assets to CDN"
  task :upload do
    CdnAssets.new.upload
  end
end
```

Adding missing step to `.github/workflows/assets.yml`:

```
     - name: Push assets to AWS S3
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: eu-central-1
          AWS_BUCKET: fancy-bucket
          GIT_COMMIT: ${{ github.sha }}
        run: |
          bin/rails cdn_assets:upload
```

### Download manifest on Heroku
Having predictable Sprockets manifest name allows us to download it on Heroku using carefully crafted [buildpack](https://github.com/arkency/heroku-buildpack-cdn-manifest). What it does is downloading `manifest-$COMMIT_SHA.json` or the fallback one to `public/assets/$ASSET_MANIFEST_PATH`. `$ASSET_MANIFEST_PATH` can be something like: `public/assets/.sprockets-manifest-5ad1cd2a52740dfb575f43c74d6f3b0e.json`. It doesn't need to change in time, it's name doesn't reference content, it has to match sprockets lookup pattern.

## Save even more time and slug size
 You want to run [cdn manifest buildpack](https://github.com/arkency/heroku-buildpack-cdn-manifest) before `heroku/ruby` default buildpack. Rails will skip `assets:precompile` because of manifest file being in place. You earn some time here and you can later limit your slug size and build time by skipping installing node, running yarn or npm by creating [.slugignore](https://devcenter.heroku.com/articles/slug-compiler#ignoring-files-with-slugignore) file:
 
```
package.json
package-lock.json
yarn.lock
```





