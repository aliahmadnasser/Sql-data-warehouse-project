Data Warehouse and Analytics Project
A hands-on implementation of a modern data warehouse built in SQL Server, following the Data With Baraa tutorial. This repository contains my own implementation of the project, including scripts for each layer, documentation, and tests.

📌 Project Overview
This project takes raw files from two systems—a CRM and an ERP—and builds one data warehouse in SQL Server. At the end, the data is clean and ready for analysis.

The project covers the full pipeline: designing the architecture, building ETL pipelines, modeling the data into facts and dimensions, and answering business questions with SQL.

🏗️ Data Architecture
The project follows the Medallion Architecture with three distinct layers:

Bronze Layer: Stores raw data as-is from the source systems. Data is ingested from CSV files into the SQL Server database.

Silver Layer: Includes data cleansing, standardization, and normalization processes to prepare data for analysis.

Gold Layer: Houses business-ready data modeled into a star schema required for reporting and analytics.

🎯 Project Requirements
Objective
Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.

Specifications
Data Sources: Import data from two source systems (ERP and CRM) provided as CSV files.

Data Quality: Cleanse and resolve data quality issues prior to analysis.

Integration: Combine both sources into a single, user-friendly data model designed for analytical queries.

📂 Repository Structure
text
sql-data-warehouse-project/
├── 00_setup/               # Setup guide, and one-click Docker start for Mac
├── 01_datasets/            # The six source files the project loads
│   ├── source_crm/         # Three files from the CRM system
│   └── source_erp/         # Three files from the ERP system
├── 02_docs/                # Requirements, diagrams, and notes
├── 03_scripts/             # Project scripts, in the order of the videos
│   ├── init_database.sql   # Creates the database: run it first
│   ├── bronze/             # Loads the raw files
│   ├── silver/             # Cleans and prepares the data
│   └── gold/               # Builds the tables for analysis
└── 04_tests/               # Checks the quality of the silver and gold data
(Structure verified against official repository)

🛠️ Tools Used
SQL Server and SSMS: The setup guide in 00_setup has the links and every step.

Git / GitHub: To save and share the project.

draw.io: To draw the architecture and the data model.

Notion: Project plan and project steps templates.

🚀 How to Run
Open the setup guide in 00_setup/ to install SQL Server and create the database.

Place the 01_datasets folder at C:\sql\dwh_project\01_datasets\, or change the six paths in 03_scripts/bronze/proc_load_bronze.sql.

Run scripts in order: init_database.sql → bronze/ → silver/ → gold/.

Run the tests in 04_tests/ to validate data quality.

Note: The videos show the folders without numbers: datasets there is 01_datasets here, scripts is 03_scripts.

📊 Data Model
The Gold layer implements a star schema consisting of fact and dimension tables, ready for reporting and analytics.

(Add your own star schema diagram here, placed in 02_docs/)

📝 Key Learnings
(Replace with your own notes, or delete this section entirely. Based on the course objectives, typical learnings include:)

Designing a three-layer medallion architecture (Bronze → Silver → Gold) in SQL Server

Building ETL pipelines with stored procedures

Handling data quality issues: deduplication, standardization, and null handling

Modeling fact and dimension tables for analytical queries

🙏 Acknowledgements
This project was built by following the Data With Baraa SQL Data Warehouse tutorial. All credit for the course structure, materials, and teaching goes to Baraa Khatib Salkini. This repository is my own implementation and learning record.

YouTube: Data With Baraa

Official Repository: DataWithBaraa/sql-data-warehouse-project

📄 License
This project is for educational purposes. Refer to the original course materials for licensing terms.
