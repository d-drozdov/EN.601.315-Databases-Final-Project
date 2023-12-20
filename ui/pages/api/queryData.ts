import { loggerSql } from "@/utils/sql";
import type { NextApiRequest, NextApiResponse } from "next";
import { procedureRecord } from "@/constants/procedure_dict";
import { createClient } from "@vercel/postgres";

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  let ip = req.headers["x-forwarded-for"] || req.socket.remoteAddress;
  console.log("ip address: ", ip);
  console.log("req.query: ", req.query);
  const queryId = parseInt(req.query.queryId as string);
  if (!queryId) {
    res.status(400).json({ error: "Missing queryId" });
    return;
  }
  if (queryId < 1 || queryId > 26) {
    res.status(400).json({ error: "Invalid queryId" });
    return;
  }

  let result;
  switch (queryId) {
    case 1:
      console.log('SELECT * FROM get_avg_costs_for_census_region();')
      result =
        await loggerSql`SELECT * FROM get_avg_costs_for_census_region();`;
      break;
    case 2:
      result =
        await loggerSql`SELECT * FROM get_avg_energy_consumption_for_industry();`;
      break;
    case 3:
      result =
        await loggerSql`SELECT * FROM get_avg_energy_consumption_for_owner_type();`;
      break;
    case 4:
      result =
        await loggerSql`SELECT * FROM get_avg_energy_consumption_for_renovation_options();`;
      break;
    case 5:
      result =
        await loggerSql`SELECT * FROM get_avg_electricity_per_sqft_by_construction_year();`;
      break;
    case 6:
      result =
        await loggerSql`SELECT * FROM get_avg_electricity_per_sqft_by_building_activity();`;
      break;
    case 7:
      result =
        await loggerSql`SELECT * FROM calculate_avg_energy_consumption();`;
      break;
    case 8:
      result =
        await loggerSql`SELECT * FROM get_avg_electricity_consumption_by_employee_category();`;
      break;
    case 9:
      result = await loggerSql`SELECT * FROM calculate_daylight_statistics();`;
      break;
    case 10:
      result =
        await loggerSql`SELECT * FROM get_daylight_buildings_statistics_by_region();`;
      break;
    case 11:
      result =
        await loggerSql`SELECT * FROM get_avg_energy_consumption_by_heating_system();`;
      break;
    case 12:
      result =
        await loggerSql`SELECT * FROM get_avg_energy_consumption_by_cooling_system();`;
      break;
    case 13:
      result =
        await loggerSql`SELECT * FROM get_water_heating_system_statistics();`;
      break;
    case 14:
      result =
        await loggerSql`SELECT * FROM get_window_energy_consumption_statistics();`;
      break;
    case 15:
      result =
        await loggerSql`SELECT * FROM get_lighting_category_energy_consumption();`;
      break;
    case 16:
      result =
        await loggerSql`SELECT * FROM get_building_size_energy_consumption();`;
      break;
    case 17:
      result =
        await loggerSql`SELECT * FROM get_roof_construction_statistics_by_construction_year();`;
      break;
    case 18:
      result =
        await loggerSql`SELECT * FROM get_wall_construction_statistics_by_construction_year();`;
      break;
    case 19:
      result =
        await loggerSql`SELECT * FROM get_air_conditioning_statistics();`;
      break;
    case 20:
      result = await loggerSql`SELECT * FROM get_heating_statistics();`;
      break;
    case 21:
      result =
        await loggerSql`SELECT * FROM get_roof_construction_material_statistics_by_owner_type();`;
      break;
    case 22:
      result =
        await loggerSql`SELECT * FROM get_wall_construction_material_statistics_by_owner_type();`;
      break;
    case 23:
      result =
        await loggerSql`SELECT * FROM get_energy_consumption_for_food_service();`;
      break;
    case 24:
      result =
        await loggerSql`SELECT * FROM get_avg_carbon_output_by_building_activity();`;
      break;
    case 25:
      result =
        await loggerSql`SELECT * FROM get_avg_carbon_output_by_accessibility_modes();`;
      break;
    case 26:
      result =
        await loggerSql`SELECT * FROM get_consolidated_energy_source_usage();`;
      break;
    default:
      return;
  }

  res.status(200).json({
    rowData: result.rows,
    fields: result.fields.map((field) => field.name),
  });
}
