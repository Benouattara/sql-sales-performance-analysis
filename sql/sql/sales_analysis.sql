CREATE TABLE Projet.customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    signup_date DATE
);
insert into Projet.customers( customer_id, first_name, last_name, country, city, signup_date) values
(1,'Amadou','Kone','France','Paris','2022-03-15'),
(2,'Sarah','Martin','France','Lyon','2021-11-20'),
(3,'Jean','Durand','France','Marseille','2023-01-10'),
(4,'Awa','Traore','Belgium','Brussels','2022-07-08'),
(5,'David','Smith','Germany','Berlin','2021-05-02');


CREATE TABLE Projet.products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);
insert into Projet.products(product_id,product_name,category,price) values
(101,'Laptop Pro','Electronics','1200'),
(102,'Wireless Mouse','Electronics','25'),
(103,'Office Chair','Furniture','180'),
(104,'Standing Desk','Furniture','450'),
(105,'Monitor 27','Electronics','320');



CREATE TABLE Projet.orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
insert into Projet.orders(order_id,customer_id,order_date,status) values
(1001,1,'2023-02-10','Completed'),
(1002,2,'2023-02-11','Completed'),
(1003,1,'2023-03-05','Completed'),
(1004,3,'2023-03-12','Cancelled'),
(1005,4,'2023-04-01','Completed'),
(1006,5,'2023-04-15','Completed');

CREATE TABLE Projet.order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
insert into Projet.order_items(order_item_id,order_id,product_id,quantity) values
(1,1001,101,1),
(2,1001,102,2),
(3,1002,103,1),
(4,1003,105,2),
(5,1005,104,1),
(6,1006,101,1);



#### ANALYSE #####

  
#chiffres d'affaires total
SELECT 
    SUM(oi.quantity * p.price) AS total_revenue
FROM Projet.order_items oi
JOIN Projet.products p ON oi.product_id = p.product_id;
# Le chiffre d’affaires est principalement généré 
# par un nombre limité de commandes à forte valeur, 
# notamment sur la catégorie Electronics.

# chiffres d'affaires mensuels
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.quantity * p.price) AS monthly_revenue
FROM Projet.orders o
JOIN Projet.order_items oi ON o.order_id = oi.order_id
JOIN Projet.products p ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year, month;
# L’analyse mensuelle met en évidence une progression 
# des ventes au fil des mois, ce qui suggère une montée 
# en puissance de l’activité commerciale.


# Top clients par chiffre d’affaires

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(oi.quantity * p.price) AS total_revenue
FROM Projet.customers c
JOIN Projet.orders o ON c.customer_id = o.customer_id
JOIN Projet.order_items oi ON o.order_id = oi.order_id
JOIN Projet.products p ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC;
# Une part significative du chiffre d’affaires est concentrée 
# sur un nombre restreint de clients à forte valeur.


#Produits les plus vendus (volume)

SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM Projet.order_items oi
JOIN Projet.products p ON oi.product_id = p.product_id
JOIN Projet.orders o ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC;
# Les produits de la catégorie Electronics génèrent à la fois 
# les plus forts volumes et le chiffre d’affaires le plus élevé.


#Produits générant le plus de chiffre d’affaires
SELECT 
    p.product_name,
    SUM(oi.quantity * p.price) AS product_revenue
FROM Projet.order_items oi
JOIN Projet.products p ON oi.product_id = p.product_id
JOIN Projet.orders o ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_name
ORDER BY product_revenue DESC;
# Le taux de réachat montre une base de clients fidèles, 
# mais avec un potentiel d’amélioration.


# Analyse géographique (par pays)
SELECT 
    c.country,
    SUM(oi.quantity * p.price) AS total_revenue
FROM Projet.customers c
JOIN Projet.orders o ON c.customer_id = o.customer_id
JOIN Projet.order_items oi ON o.order_id = oi.order_id
JOIN Projet.products p ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY c.country
ORDER BY total_revenue DESC;
# La France est en tête des pays qui génère le plus gros CA 

#Nombre de commandes par client
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders
FROM Projet.customers c
JOIN Projet.orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders DESC;
# sans suprise Amadou kone le client qui passe le plus de commande

#Clients ayant passé plus d’une commande
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_count
    FROM Projet.orders
    WHERE status = 'Completed'
    GROUP BY customer_id
)
SELECT 
    COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*) 
        AS repeat_purchase_rate
FROM customer_orders;

#Classement des clients par chiffre d’affaires (WINDOW FUNCTION)

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(oi.quantity * p.price) AS total_revenue,
    RANK() OVER (ORDER BY SUM(oi.quantity * p.price) DESC) AS revenue_rank
FROM Projet.customers c
JOIN Projet.orders o ON c.customer_id = o.customer_id
JOIN Projet.order_items oi ON o.order_id = oi.order_id
JOIN Projet.products p ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name;
# amadou a le meilleir CA 
