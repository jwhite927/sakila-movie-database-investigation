/* Query 1: Comparison of stores by month */
SELECT DATE_PART('month', r.rental_date) rental_month,
       DATE_PART('year', r.rental_date) rental_year,
       s2.store_id,
       COUNT(*) count_rentals 
  FROM rental AS r
       JOIN staff AS s1 
       ON r.staff_id = s1.staff_id
       JOIN store AS s2 
       ON s1.store_id = s2.store_id
GROUP BY 1, 2, 3
ORDER BY 2, 1, 4 DESC;


/* Query 2: Top 10 Customers */
WITH customer_top_10 AS 
      (SELECT c.customer_id, SUM(p.amount)
         FROM customer c
              JOIN payment p
              ON p.customer_id = c.customer_id
     GROUP BY 1
     ORDER BY 2 DESC
        LIMIT 10)
SELECT DATE_TRUNC('month', p.payment_date) AS pay_mon, c.first_name || ' ' || c.last_name AS fullname,
       COUNT(*) pay_counterpermon,
       SUM(p.amount) pay_amount
  FROM payment p
  JOIN customer c
    ON p.customer_id = c.customer_id AND c.customer_id IN
       (SELECT customer_id 
          FROM customer_top_10)
GROUP BY 1, 2
HAVING DATE_TRUNC('month', p.payment_date) BETWEEN '01-01-2007' AND '01-01-2008'
ORDER BY 2;

/* Query 3: Comparison of top customer spending month to month */
WITH customer_top_10 AS 
      (SELECT c.customer_id, SUM(p.amount)
         FROM customer c
              JOIN payment p
              ON p.customer_id = c.customer_id
     GROUP BY 1
     ORDER BY 2 DESC
        LIMIT 10),
     top_10_payments AS
      (SELECT DATE_TRUNC('month', p.payment_date) AS pay_mon, c.first_name || ' ' || c.last_name AS fullname,
              COUNT(*) pay_counterpermon,
              SUM(p.amount) pay_amount
         FROM payment p
              JOIN customer c
              ON p.customer_id = c.customer_id AND c.customer_id IN
                  (SELECT customer_id 
                     FROM customer_top_10)
     GROUP BY 1, 2
       HAVING DATE_TRUNC('month', p.payment_date) BETWEEN '01-01-2007' AND '01-01-2008'),   
     top_10_delta AS
      (SELECT pay_mon,
              fullname,
              pay_amount,
              LAG(pay_amount) OVER (ORDER BY fullname, pay_mon) prior_mon_pay_amount,
              CASE WHEN fullname = LAG(fullname) OVER (ORDER BY fullname, pay_mon) THEN pay_amount - LAG(pay_amount) OVER (ORDER BY fullname, pay_mon)
              ELSE NULL
              END AS delta_pay_amount
         FROM top_10_payments)
SELECT pay_mon,
       fullname,
       delta_pay_amount
 FROM top_10_delta
WHERE NOT delta_pay_amount IS NULL
ORDER BY delta_pay_amount DESC;


/* Query 4: Comparison of rentals of family films */
WITH family_films AS
     (SELECT c.name AS category_name,
             f.title AS film_title,
             i.inventory_id
        FROM film_category AS fc
             JOIN category AS c
             ON c.category_id = fc.category_id AND c.name IN
                ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
             JOIN film AS f
             ON fc.film_id = f.film_id
             JOIN inventory AS i
             ON i.film_id = f.film_id),
    family_categories AS
     (SELECT ff.film_title,
             ff.category_name,
             COUNT(*) AS rental_count,
             SUM(p.amount) AS rental_sales
        FROM family_films AS ff
             JOIN rental r
             ON r.inventory_id = ff.inventory_id
             JOIN payment p
             ON r.rental_id = p.rental_id
    GROUP BY 1, 2)
SELECT category_name,
       SUM(rental_count) AS total_rentals,
       SUM(rental_sales) AS total_sales,
       COUNT(*) AS number_of_films
  FROM family_categories
GROUP BY category_name
ORDER BY 1;
