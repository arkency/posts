# Introduction to Read Models

Welcome to the first, the most theoretical, chapter of the Read Models course. If you have already dealt with these techniques, you can brush up on your knowledge or skip to the next level.

Enjoy!

## Understand what a read model is

When you start a new application, you usually create a well-organized database structure to store your data efficiently. This process, called **normalization**, helps keep your data clean and consistent. But as your application grows and you get more users, you might face issues with performance and scaling, especially when your app has many operations that involve reading data.

To tackle these issues, you can use **read models**. Read models are special ways to organize and present data that are designed for specific reads. They involve **denormalizing** the data, which means combining or restructuring the data to make it easier and faster to access. **Denormalization helps to avoid costly joins and complex queries, which can slow down data retrieval**.

I'm not saying that normalization is something bad. I'm saying that it solves different kinds of problems that typical web application meets.
The trade-offs between the benefits of denormalization and duplication versus the additional storage costs and complexity should be carefully considered.

Here are a few examples of read models in Ruby on Rails applications:

1. E-commerce Product Catalog: In an e-commerce application, a read model can be created for the product catalog to optimize data retrieval when users browse or search for products. The read model can store denormalized product information, such as product names, descriptions, images, prices, and categories, making it faster to display the product list and search results without needing complex joins.
2. Blog Post Summaries: In a blogging platform, a read model can be created to store blog post summaries, including post titles, author names, publication dates, and a snippet of the content. This read model can optimize the display of the blog post list and allow users to quickly scan through the related posts.
3. Reporting Dashboard: In a business application, a read model can be created to store aggregated data for a reporting dashboard. This read model can contain metrics like total sales, customer count, revenue by region, and other relevant data points, allowing for fast and efficient data retrieval.

## Learn how read models differ from caching mechanisms

Read models and caching mechanisms both aim to improve data access and performance, but while **caching tends to treat the symptoms of performance issues**, read models address the underlying cause:

Read models are a targeted solution that organizes data for specific purposes or views, addressing the root cause of performance issues. By creating optimized data structures, read models ensure the application runs smoothly. This well-planned design approach focuses on providing the best data organization and synchronization for an application's needs.

Caching mechanisms, on the other hand, temporarily store frequently accessed data in a cache or buffer so that it can be quickly retrieved and served to users without having to go through the time-consuming process of accessing the original source. Caching can be very beneficial when used appropriately for the right kind of data(rarely changed, non-critical and non-confidential), but it is often overused as a hotfix for underlying performance problems.

Depending on the application's needs, read models can also be cached. **They are not exclusive alternatives. In summary, for me, read models stay for a good design, while caching is an upper layer *trick* useful in very specific cases.**

## Understand the Command Query Responsibility Segregation (CQRS) pattern

To tackle these issues, you can use **read models**. This concept is closely related to the **CQRS pattern** (Command Query Responsibility Segregation) which means having separate models for reading and writing data. The CQRS pattern is a way to separate the read and write responsibilities of an application into two different models. The write model is responsible for handling commands, such as creating, updating, and deleting data. The read model is responsible for handling queries, such as retrieving data for display.