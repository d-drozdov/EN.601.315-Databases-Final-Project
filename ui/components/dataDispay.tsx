import { Suspense } from "react";
import DataTable, { DataTableProps } from "./dataTable";

import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
} from "./ui/card";
import Loading from "./loading";
type Props = {
  isLoading: boolean;
};
const DataDispay = <T extends object>({
  fields,
  rowData,
  isLoading,
}: DataTableProps<T> & Props) => {
  console.log("fields dataDisplay", fields);
  console.log("rowData dataDisplay", rowData);
  return (
    <>
      <Card className="w-11/12">
        <CardHeader>
          <CardTitle>Data Visualizer</CardTitle>
          <div className="flex justify-center">
            <CardDescription className="w-3/4">
              This area will display the data you have selected and any
              associated visualizations. The data tables are sortable by
              clicking on the column headers.
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent className="flex justify-center">
          {isLoading ? (
            <Loading/>
          ) : (
            <DataTable fields={fields} rowData={rowData} />
          )}
        </CardContent>
      </Card>
    </>
  );
};

export default DataDispay;
