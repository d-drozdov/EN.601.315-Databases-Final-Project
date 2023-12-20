import { SetStateAction } from "react";
import QuerySelector from "./querySelector";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "./ui/card";
import { DataTableProps } from "./dataTable";

type Props = {
  setData: React.Dispatch<
    React.SetStateAction<DataTableProps<object> | undefined>
  >;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
};
const QuerySelectorCard = ({ setData, setIsLoading }: Props) => {
  return (
    <>
      <Card className="w-[700px]">
        <CardHeader>
          <CardTitle>Please select your query</CardTitle>
          <CardDescription>
            Use this area to select your queries
          </CardDescription>
        </CardHeader>
        <CardContent className="flex justify-center">
          <QuerySelector setData={setData} setIsLoading={setIsLoading} />
        </CardContent>
      </Card>
    </>
  );
};

export default QuerySelectorCard;
