CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
----------------------------------------------------------
/* --------------------
   Case Study Questions
   --------------------*/
SELECT *
FROM members
SELECT *
FROM members;
SELECT *
FROM menu;
SELECT *
FROM sales  
  
-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total
FROM menu AS m JOIN sales AS s ON m.product_id = s.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS visitedDay
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM(SELECT customer_id, product_name, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
     FROM menu AS m JOIN sales AS s ON m.product_id = s.product_id) AS a
WHERE ranking = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(product_name) AS purchased_total
FROM menu AS m JOIN sales AS s ON m.product_id = s.product_id
GROUP BY product_name
ORDER BY purchased_total DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH customer_p AS(
SELECT customer_id, product_name, COUNT(*) AS total
FROM menu AS m JOIN sales AS s ON m.product_id = s.product_id
GROUP BY customer_id, product_name)
SELECT customer_id, product_name
FROM(SELECT customer_id, product_name, 
       DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY total DESC) AS ranking
FROM customer_p) AS a
WHERE ranking = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH before_mem AS(
SELECT m.customer_id, product_id,
	   DENSE_RANK() OVER(PARTITION BY m.customer_id ORDER BY order_date ASC) as ranking
FROM members AS m JOIN sales AS s ON m.customer_id = s.customer_id
WHERE join_date > order_date)
SELECT b.customer_id, m.product_name
FROM before_mem AS b JOIN menu AS m ON b.product_id = m.product_id
WHERE ranking = 1

-- 7. Which item was purchased just before the customer became a member?
WITH customer_p AS(
SELECT customer_id, product_name, COUNT(*) AS total
FROM menu AS m JOIN sales AS s ON m.product_id = s.product_id
GROUP BY customer_id, product_name)
SELECT customer_id, product_name
FROM(SELECT customer_id, product_name, 
       DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY total DESC) AS ranking
FROM customer_p) AS a
WHERE ranking = 1  
  
-- 8. Which item was purchased first by the customer after they became a member?
WITH after_mem AS(
SELECT m.customer_id, product_id,
	   DENSE_RANK() OVER(PARTITION BY m.customer_id ORDER BY order_date ASC) as ranking
FROM members AS m JOIN sales AS s ON m.customer_id = s.customer_id
WHERE join_date < order_date)
SELECT b.customer_id, m.product_name
FROM after_mem AS b JOIN menu AS m ON b.product_id = m.product_id
WHERE ranking = 1  
  
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT m.customer_id, COUNT(mn.product_id) AS total_items, SUM(price) AS amount_spent
FROM members AS m JOIN sales AS s ON m.customer_id = s.customer_id
                  JOIN menu AS mn ON mn.product_id= s.product_id 
WHERE join_date > order_date
GROUP BY m.customer_id
ORDER BY m.customer_id
  
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,
       SUM(CASE WHEN product_name ='sushi' THEN price *20
	   ELSE price*10 END) AS point
FROM menu AS m JOIN sales AS s ON m.product_id = s.product_id
GROUP BY customer_id
ORDER BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT m.customer_id,
       SUM(CASE 
		   WHEN order_date -join_date <= 6 AND order_date -join_date >=0 THEN 20*mn.price 
		   WHEN mn.product_name = 'sushi' THEN 20 * mn.price
	   ELSE 10*price END) AS total_point
FROM members AS m JOIN sales AS s ON m.customer_id = s.customer_id
                  JOIN menu AS mn ON mn.product_id= s.product_id 
WHERE  order_date <= '2021-01-31'
GROUP BY m.customer_id
ORDER BY m.customer_id 
