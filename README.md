# E-Wallet Database Transaction Processing System

## Abstract
This repository contains the source code, database design, and technical documentation for an E-Wallet and Transaction Management System. Developed as a practical project for the IS210 (Database Management Systems) course, the project demonstrates the robust application of relational database concepts in executing and managing financial operations. The architectural design strictly encapsulates core wallet functionalities, deterministic transaction processing, and concurrency control, intentionally excluding anomalous or fraud detection modules as per project specifications.

## System Architecture
The project adopts a multi-tier architecture to ensure high cohesion and clear separation of concerns:
- **Database Layer (SQL)**: Acts as the core engine for data persistence, integrity enforcement, and transaction safety. It heavily utilizes advanced database objects (Stored Procedures, Functions, Triggers) to guarantee ACID properties during concurrent financial operations.
- **Backend Layer (Python/FastAPI)**: Serves as a RESTful API gateway, managing secure communication between the client and the database. It handles user authentication, request validation, and orchestrates calls to database procedures.
- **Frontend Layer (React Native/Expo)**: A mobile client application providing a streamlined user interface for financial interactions, including QR code scanning, transaction history tracking, and wallet management.

## Detailed Implementations & Key Functionalities

### 1. Relational Database Design & Integrity
- Designed a fully normalized database schema managing User Profiles, Wallets, Linked Payment Methods, Transaction Logs (Deposits, Withdrawals, P2P Transfers), Vouchers, and Application Sessions.
- Enforced strict domain constraints, primary/foreign key relationships, and data validation rules to prevent orphan records and maintain financial accuracy.

### 2. Transaction Processing & Concurrency Control
- **ACID-Compliant Procedures**: Implemented complex, multi-step stored procedures for core financial transactions (Deposit, Withdrawal, P2P Transfer, Reversal).
- **Concurrency Management**: Addressed potential race conditions (e.g., double-spending) and isolation anomalies during simultaneous transactions to ensure consistent balance updates.

### 3. Advanced Database Logic (Triggers & Functions)
- **Automated Workflows (Triggers)**: Developed triggers for automatic fee deduction, real-time wallet balance recalculation, transaction state validation, and comprehensive system audit logging.
- **Business Rule Encapsulation (Functions/Procedures)**: Moved core business logic to the database level, including:
  - Secure PIN verification and session validation.
  - Evaluation of promotional voucher eligibility and discount computation.
  - Enforcement of daily/monthly transaction limits and minimum balance requirements.

### 4. API & Frontend Integration
- **RESTful Endpoints**: Built modular routing modules (`auth`, `users`, `wallets`, `transactions`, `vouchers`, `payment_methods`) utilizing FastAPI dependency injection and security standards.
- **Mobile Client**: Deployed functional React Native screens for user onboarding, interactive transaction workflows, and historical data visualization.

### 5. Data Simulation & Testing
- Engineered structured SQL seed scripts (`seed_01` to `seed_06`) to populate master data and simulate diverse transactional scenarios.
- Conducted exhaustive testing on boundary conditions, transaction rollbacks, payment reversals, and refund workflows to validate system resilience.

## Repository Structure
- `/backend`: Python API source code, environment configurations, and dependency manifests.
- `/frontend`: React Native source code, encompassing UI components, screen layouts (`/app`), and asset management.
- `/simulated_data`: Sequential SQL scripts for database population and scenario testing.
- `create_DB.sql`: Core relational database schema definition (DDL).
- `IS210_Ewallet_function.sql` / `_procedure.sql` / `_trigger.sql`: Procedural SQL scripts for operational logic (DML/DCL).

## Authors
- Nguyễn Đăng Khôi (23520773)
- Hồ Như Hồng Ngọc (23521021)
- Võ Ngọc Anh Thy (23521565)
- Nguyễn Nhật Tân (24521580)

## Acknowledgments
This project was completed under the supervision of KS. Lê Võ Đình Kha at the University of Information Technology (UIT) - VNUHCM, 2026.
