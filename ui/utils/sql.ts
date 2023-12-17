import {
  type QueryResult,
  type QueryResultRow,
  sql as vercelSql,
} from "@vercel/postgres";

export const loggerSql = async (
  strings: TemplateStringsArray,
  ...values: Primitive[]
): Promise<QueryResult<QueryResultRow>> => {
  return await logQuery(strings, ...values);
};

type Primitive = string | number | boolean | undefined | null;
const logQuery = async (
  strings: TemplateStringsArray,
  ...values: Primitive[]
): Promise<QueryResult<QueryResultRow>> => {
  const startTime = performance.now();

  const query = strings.reduce((prev, current, i) => {
    return prev + current + (values[i] !== undefined ? values[i] : "");
  }, "");

  try {
    console.log(`Executing query:, [ ${query} ]`);
    const result = await vercelSql(strings, ...values);
    const endTime = performance.now(); // End timing
    const queryTime = ((endTime - startTime) / 1000).toFixed(3);
    console.log(`✅ Query executed successfully in ${queryTime} s`);
    return result; // Typecast the result to QueryResult<O>
  } catch (error) {
    const endTime = performance.now();
    const queryTime = ((endTime - startTime) / 1000).toFixed(3);
    console.error(`❌ Query failed after ${queryTime} ms\n\n`, error);
    throw error;
  }
};
