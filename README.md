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




# Questions for Querying:
1. What is the average cost of roof and wall construction materials for buildings located in each census region?
2. How does the average annual electricity and natural gas consumption compare across different principal building activities and building owner types?
3. What is the average electricity and natural gas consumption for buildings that have undergone specific types of renovations (like HVAC equipment upgrade, insulation upgrade) compared to those that haven't?
4. What is the average electricity consumption per square foot for buildings, categorized by their construction year range? Usage type?
5. Do elevators and escalators significantly affect a building's overall energy consumption?
6. Which industry is the most energy intensive? (For example, healthcare vs. foodservice) Which one uses the least energy?
7. Is there a correlation between the number of employees and electricity consumption in buildings?
8. For buildings that receive significant daylight (>50% daylight shining on the building), how does their electricity consumption for lighting compare to those with less daylight?
9. Compare the energy consumption of buildings with different types of heating and cooling systems. Find heating and cooling efficiency (energy consumption per square foot) for each type of system.
10. What are the most common fuel types used for water heating in buildings across different census regions?
11. Analyze how different window types (e.g., tinted, reflective) affect heating and cooling energy consumption.
12. Evaluate the impact of various lighting technologies (LED, fluorescent, etc.) and lighting control systems on a building's electricity consumption.
13. How does energy consumption (electricity, natural gas) vary with the size of the building (square footage)? Does efficiency increase or decrease with building size?
14. Does the year of construction affect the materials chosen for either roofs or walls?
15. What are the most common types of air conditioning and heating systems used in buildings, and how do they correlate with building size and type?
16. What are the most common roof and wall construction materials used in buildings owned by different types of entities (e.g., private, government, non-profit)?
17. In buildings with food service facilities, how does the usage of natural gas vary compared to buildings without such facilities?
18. Which industries are most likely to adopt advanced lighting technologies like LEDs and lighting control systems? What about public vs private?
19. What is the efficiency of different water heating systems (measured by energy consumption per unit of hot water produced) categorized by the fuel type used (e.g., electricity, natural gas, solar)?
20. Is there a preference for certain types of energy sources in buildings of specific age categories?
21. How does the energy usage (electricity and natural gas) compare between buildings that have undergone major renovations and those that have not, within the same size and activity category?
22. What types of air conditioning systems are most commonly used in buildings located in the warmest census regions?
23. What is the most common type of heating equipment in buildings over 100,000 square feet?
24. Does the variety of energy sources used differ significantly in buildings that are open 24/7 compared to those with more standard operating hours?
25. How does the choice of fuel for water heating vary between buildings smaller than 10,000 square feet and those larger than 50,000 square feet?