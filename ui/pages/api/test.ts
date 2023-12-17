import { loggerSql } from "@/utils/sql";
import type { NextApiRequest, NextApiResponse } from "next";

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const results =
    await loggerSql`SELECT * FROM building_owner_type;`;
  res
    .status(200)
    .json({
      rows: results.rows,
      fields: results.fields.map((field) => field.name),
    });
}
