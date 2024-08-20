#!/bin/bash
apt update -y
apt install -y apache2
systemctl enable apache2
systemctl start apache2
echo "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Web Commerce Application</title>
    <link rel="stylesheet" href="styles.css"> <!-- Link to your CSS file -->
</head>
<body>
    <!-- Header -->
    <header>
        <nav class="navbar">
            <div class="logo">
                <a href="#">MyStore</a>
            </div>
            <ul class="nav-links">
                <li><a href="#">Home</a></li>
                <li><a href="#">Shop</a></li>
                <li><a href="#">About</a></li>
                <li><a href="#">Contact</a></li>
            </ul>
            <div class="user-options">
                <a href="#">Login</a>
                <a href="#" onclick="fetchCart()">Cart (<span id="cart-count">0</span>)</a>
            </div>
        </nav>
    </header>

    <!-- Hero Section -->
    <section class="hero">
        <div class="hero-content">
            <h1>Welcome to MyStore</h1>
            <p>Your one-stop shop for the best products!</p>
            <a href="#" class="btn">Shop Now</a>
        </div>
    </section>

    <!-- Featured Products -->
    <section class="featured-products">
        <h2>Featured Products</h2>
        <div class="product-grid">
            <!-- Products will be dynamically inserted here by JavaScript -->
        </div>
    </section>

    <!-- Product Details Section (optional for displaying details on the same page) -->
    <section class="product-details">
        <!-- Product details will be dynamically inserted here by JavaScript -->
    </section>

    <!-- Cart Display Section -->
    <section class="cart-items">
        <h2>Your Cart</h2>
        <!-- Cart items will be dynamically inserted here by JavaScript -->
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-content">
            <p>&copy; 2024 MyStore. All rights reserved.</p>
            <ul class="footer-links">
                <li><a href="#">Privacy Policy</a></li>
                <li><a href="#">Terms of Service</a></li>
                <li><a href="#">Contact Us</a></li>
            </ul>
        </div>
    </footer>

    <!-- JavaScript -->
    <script src="script.js"></script> <!-- Link to your JS file -->
</body>
</html>
" > /var/www/html/index.html

echo "// Base URL of the API
const apiUrl = 'http://localhost:5000/';

// Function to fetch all products
function fetchProducts() {
    fetch(`${apiUrl}?action=getProducts`)
        .then(response => response.json())
        .then(data => {
            displayProducts(data);
        })
        .catch(error => console.error('Error fetching products:', error));
}

// Function to fetch details of a single product
function fetchProductDetails(productId) {
    fetch(`${apiUrl}?action=getProductDetails&id=${productId}`)
        .then(response => response.json())
        .then(data => {
            displayProductDetails(data);
        })
        .catch(error => console.error('Error fetching product details:', error));
}

// Function to add a product to the cart
function addToCart(productId) {
    fetch(`${apiUrl}?action=addToCart&id=${productId}`)
        .then(response => response.json())
        .then(data => {
            alert(data.message);
            updateCartDisplay(data.cart);
        })
        .catch(error => console.error('Error adding product to cart:', error));
}

// Function to fetch the current cart contents
function fetchCart() {
    fetch(`${apiUrl}?action=getCart`)
        .then(response => response.json())
        .then(data => {
            updateCartDisplay(data);
        })
        .catch(error => console.error('Error fetching cart:', error));
}

// Function to display products
function displayProducts(products) {
    const productGrid = document.querySelector('.product-grid');
    productGrid.innerHTML = products.map(product => `
        <div class="product-card">
            <img src="${product.image}" alt="${product.name}">
            <h3>${product.name}</h3>
            <p>$${Number(product.price).toFixed(2)}</p>
            <button class="btn add-to-cart-btn" data-id="${product.id}">Add to Cart</button>
        </div>
    `).join('');

    document.querySelectorAll('.add-to-cart-btn').forEach(button => {
        button.addEventListener('click', () => addToCart(button.dataset.id));
    });

    // Attach event listeners to the "Add to Cart" buttons
    document.querySelectorAll('.add-to-cart-btn').forEach(button => {
        button.addEventListener('click', () => {
            const productId = button.getAttribute('data-id');
            addToCart(productId);
        });
    });
}

// Function to display details of a single product
function displayProductDetails(product) {
    const productDetailsSection = document.querySelector('.product-details');
    productDetailsSection.innerHTML = `
        <img src="${product.image}" alt="${product.name}">
        <h3>${product.name}</h3>
        <p>$${product.price.toFixed(2)}</p>
        <p>${product.description}</p>
        <button class="btn add-to-cart-btn" data-id="${product.id}">Add to Cart</button>
    `;

    // Attach event listener to the "Add to Cart" button
    document.querySelector('.add-to-cart-btn').addEventListener('click', () => {
        addToCart(product.id);
    });
}

function updateCartDisplay(cart) {
    const cartItems = document.querySelector('.cart-items');
    cartItems.innerHTML = cart.length ? cart.map(item => `
        <div class="cart-item">
            <img src="${item.image}" alt="${item.name}">
            <h4>${item.name}</h4>
            <p>$${Number(item.price).toFixed(2)}</p>
            <p>Quantity: ${Number(1)}</p>
        </div>
    `).join('') : 'Your cart is empty.';
}



// Initialize the app by fetching and displaying the products
document.addEventListener('DOMContentLoaded', () => {
    fetchProducts();
    fetchCart(); // Optionally fetch and display the cart contents on page load
});
" > /var/www/html/script.js

echo "/* General Styles */
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 0;
    background-color: #f5f5f5;
    color: #333;
}

/* Navbar Styles */
.navbar {
    background-color: #333;
    color: white;
    padding: 1rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.navbar .logo a {
    color: white;
    text-decoration: none;
    font-size: 1.5rem;
    font-weight: bold;
}

.nav-links {
    list-style-type: none;
    margin: 0;
    padding: 0;
    display: flex;
    gap: 1rem;
}

.nav-links a {
    color: white;
    text-decoration: none;
    padding: 0.5rem 1rem;
    transition: background-color 0.3s;
}

.nav-links a:hover {
    background-color: #555;
}

.user-options a {
    color: white;
    text-decoration: none;
    margin-left: 1rem;
}

/* Hero Section Styles */
.hero {
    background: url('https://images.unsplash.com/photo-1671202867630-c897313a0a22?q=80&w=1957&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D') no-repeat center center/cover;
    height: 80vh;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    text-align: center;
}

.hero h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
}

.hero p {
    font-size: 1.5rem;
    margin-bottom: 2rem;
}

.hero .btn {
    background-color: #ff6347;
    color: white;
    padding: 0.75rem 2rem;
    text-decoration: none;
    border-radius: 5px;
    font-size: 1rem;
}

.hero .btn:hover {
    background-color: #ff4500;
}

/* Featured Products Section Styles */
.featured-products {
    padding: 2rem;
    background-color: white;
    text-align: center;
}

.featured-products h2 {
    font-size: 2rem;
    margin-bottom: 1rem;
}

.product-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1.5rem;
}

.product-card {
    background-color: #fff;
    border: 1px solid #ddd;
    border-radius: 5px;
    padding: 1rem;
    text-align: center;
}

.product-card img {
    max-width: 100%;
    height: auto;
    border-radius: 5px;
    margin-bottom: 1rem;
}

.product-card h3 {
    font-size: 1.25rem;
    margin-bottom: 0.5rem;
}

.product-card p {
    font-size: 1rem;
    margin-bottom: 1rem;
    color: #ff6347;
}

.product-card .btn {
    background-color: #333;
    color: white;
    padding: 0.5rem 1rem;
    text-decoration: none;
    border-radius: 5px;
    font-size: 0.875rem;
}

.product-card .btn:hover {
    background-color: #555;
}

/* Product Details Section Styles */
.product-details {
    padding: 2rem;
    background-color: #f9f9f9;
    text-align: center;
}

.product-details img {
    max-width: 300px;
    height: auto;
    margin-bottom: 1rem;
    border-radius: 5px;
}

.product-details h3 {
    font-size: 1.75rem;
    margin-bottom: 0.5rem;
}

.product-details p {
    font-size: 1rem;
    margin-bottom: 1rem;
    color: #333;
}

.product-details .btn {
    background-color: #ff6347;
    color: white;
    padding: 0.75rem 2rem;
    text-decoration: none;
    border-radius: 5px;
    font-size: 1rem;
}

.product-details .btn:hover {
    background-color: #ff4500;
}

/* Cart Display Section Styles */
.cart-display {
    padding: 2rem;
    background-color: #fff;
    text-align: center;
}

.cart-display h2 {
    font-size: 2rem;
    margin-bottom: 1rem;
}

.cart-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid #ddd;
    padding: 1rem 0;
    margin-bottom: 1rem;
}

.cart-item img {
    max-width: 50px;
    height: auto;
    margin-right: 1rem;
    border-radius: 5px;
}

.cart-item h4 {
    font-size: 1.25rem;
    margin: 0;
}

.cart-item p {
    font-size: 1rem;
    margin: 0;
    color: #ff6347;
}

/* Footer Styles */
footer {
    background-color: #333;
    color: white;
    padding: 1rem;
    text-align: center;
}

.footer-links {
    list-style-type: none;
    margin: 0;
    padding: 0;
    display: flex;
    justify-content: center;
    gap: 1rem;
    margin-top: 1rem;
}

.footer-links a {
    color: white;
    text-decoration: none;
}

.footer-links a:hover {
    text-decoration: underline;
}
" > /var/www/html/styles.css