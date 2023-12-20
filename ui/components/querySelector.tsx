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
} from "@/components/ui/select";
import { toast } from "@/components/ui/use-toast";
import axios from "axios";

import { procedureRecord } from "@/constants/procedure_dict";
import { useRouter } from "next/router";
import { DataTableProps } from "./dataTable";

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

  const procedureOptions = Object.entries(procedureRecord).map(
    ([key, value]) => {
      return (
        <SelectItem key={key} value={key}>
          {`${key}) ${value.question}`}
        </SelectItem>
      );
    }
  );

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
                  {procedureOptions}
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
