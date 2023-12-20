import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import * as z from "zod";

import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormMessage,
} from "@/components/ui/form";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  SelectGroup,
} from "@/components/ui/select";
import { toast } from "@/components/ui/use-toast";
import axios from "axios";

import { procedureRecord } from "@/constants/procedure_dict";
import { DataTableProps } from "./dataTable";
import { SelectLabel } from "@radix-ui/react-select";

const FormSchema = z.object({
  query: z.string({
    required_error: "Please select an query to display.",
  }),
});

type Props = {
  setData: React.Dispatch<DataTableProps<object> | undefined>;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
};

const QuerySelector = ({ setData, setIsLoading }: Props) => {
  const form = useForm<z.infer<typeof FormSchema>>({
    resolver: zodResolver(FormSchema),
  });

  async function onSubmit() {
    setIsLoading(true);
    toast({
      title: `Query Submitted`,
    });
    const res = await axios.get(`api/queryData`, {
      params: {
        queryId: form.getValues("query"),
      },
    });
    console.log("res", res.data);
    setData(res.data);
    setIsLoading(false);
  }

  const proceduresSplit = {
    VISUALIZED: [],
    DATA: [],
  } as Record<
    string,
    Array<{
      question: string;
      functionName: string;
      visualType: number | null;
      id: string;
    }>
  >;
  
  for (const [key, value] of Object.entries(procedureRecord)) {
    let newRecord = { ...value, id: key };
    if (value.visualType !== null) {
      proceduresSplit.VISUALIZED.push(newRecord);
    } else {
      // Otherwise, add it to "DATA"
      proceduresSplit.DATA.push(newRecord);
    }
  }
  console.log("proceduresSplit", proceduresSplit)

  return (
    <Form {...form}>
      <form
        onSubmit={form.handleSubmit(onSubmit)}
        className="space-y-6 w-[600px]"
      >
        <FormField
          control={form.control}
          name="query"
          render={({ field }) => (
            <FormItem>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a query to display" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent className="w-[600px]">
                  <SelectGroup>
                    <SelectLabel className="font-semibold ml-2">
                      Visualization and Data
                    </SelectLabel>
                    {proceduresSplit.VISUALIZED.map((item, index) => (
                      <SelectItem key={item.question} value={item.id}>
                        {`${index + 1}) ${item.question}`}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                  <SelectGroup>
                    <SelectLabel className="font-semibold ml-2">
                      {" "}
                      Data Only{" "}
                    </SelectLabel>
                    {proceduresSplit.DATA.map((item, index) => (
                      <SelectItem key={item.id} value={item.question}>
                        {`${index + 1}) ${item.question}`}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">Submit</Button>
      </form>
    </Form>
  );
};

export default QuerySelector;
