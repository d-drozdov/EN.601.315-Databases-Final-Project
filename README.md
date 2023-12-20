# Final Project for Databases Fall 2023
## Deployment
Deployed to vercel at this link: https://db-final.vercel.app/
Use `vercel --prod` to deploy to production


## Local Development
### Requirements:
- Python 3.10
- PIP
- Docker

### Local Setup
1. Clone the repo 
2. Run `docker compose up -d`
3. To connect to this db use the following connection string: `postgresql://postgres:postgres@localhost:5432/postgres`
4. Create the database then select it in your ide  
5. Run the `database_setup.sql` script
6. Run the `insert_statements.sql` script

#### If you need to rerun the insertion scripts for some reason 
1. Switch into the `python_scripts`
2. Create a virtual environment using `python -m venv venv`
3. Activate the virtual environment using `source venv/bin/activate`
4. Run `pip install -r requirements.txt`

