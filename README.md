# Posts

Blogposts featured on [blog.arkency.com](https://blog.arkency.com). This content is fetched with [nanoc-github](https://github.com/pawelpacana/nanoc-github).

## Improving existing content

Found a typo? Code not working? Submit a pull-request.

## Creating new post

```
./bin/new_post -t "How to tell a compelling story"
```

## ERB code blocks
If you want to use ERB code blocks in your post, remember to use double-percent marks because the content is run through eRuby on compilation.

```
<%%= tags_for(item, none_text: "", base_url: "#") %>
```
