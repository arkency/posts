---
created_at: 2022-11-03 10:53:38 +0100
author: Szymon Fiedler
tags: ["rspec", "testing", "ruby on rails"]
publish: false
---

# Test which reminded me why I don't really like RSpec

Recently, our friend from a different software company asked us for some help with mutant setup. We asked to share a sample test to discover what can be wrong. When I read the snippet on a slack channel, I have immediately wrote: _Oh man, this example reminds me why I don't like RSpec_.

<!-- more -->

Just to be clear: I have no problem with the RSpec library itself. It's a great tool, I've used it in several projects, but I don't like how a lot of people utilise it. Let's have a look at it.

Let's have a look at the original example:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Students::Update do
  let(:user) { create(:user) }
  let(:params) { { last_name: "something" } }
  subject(:result) { described_class.call(current_user: user, params: params) }

  context "when user is a student" do
    it { is_expected.to be_success }
  end

  context "when user is teacher" do
    let(:user) { create(:user, :teacher) }
    it { is_expected.to be_failure }
  end

  describe "checking Address update" do
    let(:new_zip_code) { Faker::Address.zip_code }
    before { params[:zip_code] = new_zip_code }

    context "when user has address and want to change something in their address" do
      let!(:address) { create(:address, owner: user) }

      it "will succeed" do
        expect(result.success?).to eq(true)
        expect(address.reload.zip_code).to eq(new_zip_code)
      end
    end

    context "when user has not have any address and want to change something in their address" do
      let(:new_zip_code) { Faker::Address.zip_code }
      before { params[:zip_code] = new_zip_code }
      it { is_expected.to be_success }
      it "create address with given params" do
        expect { result }.to change(Address.all, :count).from(0).to(1)
        expect(Address.last.zip_code).to eq(new_zip_code)
        expect(user.address).to eq(Address.last)
      end
    end
  end

  describe "checking parent update" do
    let(:parent_first_name) { Faker::Name.female_first_name }
    let(:params) { { parent: { first_name: parent_first_name } } }

    context "when user has parent and want to change something" do
      let(:parent) { create(:parent) }
      let(:user) { create(:user, profession: student) }
      let(:student) { create(:student, parent: parent) }

      it { is_expected.to be_success }
      it "will succeed" do
        result
        expect(parent.reload.first_name).to eq(parent_first_name)
      end
    end

    context "when user has not have any parent and want to change something in their parent" do
      it { is_expected.to be_success }
      it "will create parent with given params" do
        expect { result }.to change(Parent.all, :count).from(0).to(1)
        expect(Parent.last.reload.first_name).to eq(parent_first_name)
        expect(user.profession.parent).to eq(Parent.last)
      end
    end
  end
end
```

Here's a list of my thoughts after reading test above:

- RSpec specific syntax sugar to actual test code ratio is too d\*mn high
- Tests should be verbose about their subject, not about the plumbing around.
- I don't get what the test is about, it's unreadable because of the nested `it` in `context`

   — _hey, but we have IDEs which can fold the blocks of code_
   
   — _Cool, but not here on Slack, nor on GitHub where you usually make your code reviews. I simply don't want to jump around the file to see what's the input to a service call._
   
- Setup is done through `FactoryBot` which sets some artificial database state, often not following the business rules (if your business rules live in `ActiveRecord` models — I'm sorry, we're past that since years). It's better to use domain services to setup the initial state. I've seen a lot of codebases struggling with gigantic test execution time because of too many database object being created because of how `FactoryBot` was used.
- `context` is only used to overwrite `let`, so there's different setup in different examples. Why not keep the structure flat and do the setup explicit in every example? If you need something different that declared in `let`, just use local variable in the example. `let` is great for specifying dependencies and things that don't change per each test case.
- The main input to this class giving different outcomes are `params` — this should be clearly visible how they differ in the input and what output they give, why not pass them explicitly to `call`?
- Scope the test expectations, making assertion on `Parent.all` won't give any guarantee that the service assigned data to a desired `Parent` object.

Talk is cheap, so I did a 5 minutes refactoring resulting in this:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Students::Update do
  test "when user is a student" do
    expect(Api::Students::Update.call(current_user: user, params: { last_name: "something" })).to be_success
  end

  test "when user is a teacher" do
    expect(Api::Students::Update.call(current_user: teacher, params: { last_name: "something" })).to be_failure
  end

  test "when user has address and want to change something in their address will succeed" do
    address = create(:address, owner: user)

    result = Api::Students::Update.call(current_user: user, params: { last_name: "something", zip_code: new_zip_code })

    expect(result.success?).to eq(true)
    expect(address.reload.zip_code).to eq(new_zip_code)
  end

  test "when user has not have any address and want to change something in their address create address with given params" do
    result =
      expect {
        Api::Students::Update.call(current_user: user, params: { last_name: "something", zip_code: new_zip_code })
      }.to change(Address.all, :count).from(0).to(1)

    expect(result.success?).to eq(true)
    expect(Address.last.zip_code).to eq(new_zip_code)
    expect(user.address).to eq(Address.last)
  end

  test "when user has parent and want to change something" do
    user = create(:user, profession: student)

    result = Api::Students::Update.call(current_user: user, params: { parent: { first_name: parent_first_name } })

    expect(result).to be_success
    expect(parent.reload.first_name).to eq(parent_first_name)
  end

  test "when user has not have any parent and want to change something in their parent" do
    user = create(:user, profession: student)

    result =
      expect {
        Api::Students::Update.call(current_user: user, params: { parent: { first_name: parent_first_name } })
      }.to change(Parent.all, :count).from(0).to(1)

    expect(result).to be_success
    expect(Parent.last.reload.first_name).to eq(parent_first_name)
    expect(user.profession.parent).to eq(Parent.last)
  end

  let(:user) { create(:user) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:student, parent: parent) }
  let(:parent) { create(:parent) }
  let(:new_zip_code) { Faker::Address.zip_code }
  let(:parent_first_name) { Fake::Name.female_first_name }
end
```

What are your thoughts? Which version is more readable to you?
