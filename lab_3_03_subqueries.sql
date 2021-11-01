-- Lab 3.03

/*************************************************************************************
1. How many copies of the film Hunchback Impossible exist in the inventory system?
2. List all films whose length is longer than the average of all the films.
3. Use subqueries to display all actors who appear in the film Alone Trip.
4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
5. Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.
6. Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films. First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.
7. Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer ie the customer that has made the largest sum of payments
8. Customers who spent more than the average payments.
***************************************************************************************/


-- 1. How many copies of the film Hunchback Impossible exist in the inventory system?
select count(*) as copies_of_hunchback_impossible_in_inventory
from sakila.inventory i
where i.film_id = (select film_id from sakila.film f where f.title = 'Hunchback Impossible'); -- 6

-- checking
select film_id from sakila.film f where f.title = 'Hunchback Impossible'; -- 439

select count(*) 
from sakila.inventory i where film_id = 439; -- 6


-- 2. List all films whose length is longer than the average of all the films.
select f.film_id, f.title
from sakila.film f
where f.length > (select avg(length) from sakila.film);


-- 3. Use subqueries to display all actors who appear in the film Alone Trip.
select first_name, last_name
from sakila.actor a
inner join (select actor_id from sakila.film_actor fa inner join sakila.film f on fa.film_id = f.film_id and f.title = 'Alone Trip') actors_in_alone_trip on a.actor_id = actors_in_alone_trip.actor_id;


-- 4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. 
-- Identify all movies categorized as family films.
select f.film_id, f.title, c.name, f.rating
from sakila.film f
inner join sakila.film_category fc on f.film_id = fc.film_id
inner join sakila.category c ON c.category_id = fc.category_id
where c.name = 'Family';


-- 5. Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to 
-- create a join, you will have to identify the correct tables with their primary keys and foreign keys, that 
-- will help you get the relevant information.
select first_name, last_name, email
from sakila.customer 
where address_id in (select address_id 
                     from sakila.address 
                     where city_id in (select city_id 
                                       from sakila.city 
                                       where country_id in (select country_id 
                                                            from sakila.country 
                                                            where country = 'Canada'
                                                            )
                                       )
                    );

select c.first_name, c.last_name, c.email
from sakila.customer c
inner join sakila.address a on c.address_id = a.address_id
inner join sakila.city ci on ci.city_id = a.city_id
inner join sakila.country co on co.country_id = ci.country_id
where co.country = 'Canada';


-- 6. Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has
-- acted in the most number of films. First you will have to find the most prolific actor and then use that actor_id 
-- to find the different films that he/she starred.

select f.film_id, f.title
from sakila.film f
inner join sakila.film_actor fa on f.film_id = fa.film_id
where fa.actor_id in 
  (select actor_id from (
                        select actor_id, count(*) as appearances
                        from sakila.film_actor fa 
                        group by 1
                        order by appearances desc
                        limit 1) x
  );

-- alternative without using order/limit

select f.film_id, f.title
from sakila.film f
inner join sakila.film_actor fa on f.film_id = fa.film_id
where fa.actor_id in 
             (select actor_id from (
                      select actor_id, count(*) appearances 
                      from sakila.film_actor fa
                      group by 1
                      having appearances = (select max(appearances) from (select actor_id, count(*) as appearances
                                                                          from sakila.film_actor fa 
                                                                          group by 1) x
                      )) x
  );
 
 
-- 7. Films rented by most profitable customer. You can use the customer table and payment table to find the
-- most profitable customer ie the customer that has made the largest sum of payments
select * from sakila.payment limit 10;

select f.title as films_rented_by_top_customer
from sakila.rental r
inner join (select customer_id
            from sakila.payment p
            group by 1
            order by sum(amount) desc
            limit 1) top_customer on top_customer.customer_id = r.customer_id
inner join sakila.inventory i ON i.inventory_id = r.inventory_id
inner join sakila.film f on i.film_id = f.film_id;


-- 8. Customers who spent more than the average payments.

select p.customer_id, sum(p.amount) as amount_spent
from sakila.payment p
group by 1; -- total amount spent by each customer

select avg(p.amount) as avg_amount
from sakila.payment p; -- average payment -- ~4.2

select min(amount_spent) from (select p.customer_id, sum(p.amount) as amount_spent
                              from sakila.payment p
                              group by 1) x; -- min amount spent is 50
                              
-- since we'll just get all results, i'll look at the customers total spent is greater than the average customer total spend.

select p.customer_id, sum(p.amount) as amount_spent
from sakila.payment p
group by 1
having amount_spent > (
  select avg(amount_spent) as avg_spend
  from (select p.customer_id, sum(p.amount) as amount_spent
        from sakila.payment p
        group by 1) customer_spend); -- avg customer spend = 112



-- alternative:
select * from(
  select customer_id, amount_spent, avg(amount_spent) over () as avg_amount_spent
  from (
    select p.customer_id, sum(p.amount) as amount_spent
    from sakila.payment p
    group by 1) x
    ) y
where amount_spent > avg_amount_spent;