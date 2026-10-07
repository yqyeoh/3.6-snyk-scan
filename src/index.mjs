import { z } from "zod";

const Input = z.object({
  name: z.string().min(1).max(50).default("World"),
});

export const handler = async (event) => {
  const result = Input.safeParse(event ?? {});
  if (!result.success) {
    return {
      statusCode: 400,
      body: JSON.stringify({ errors: result.error.issues }),
    };
  }

  console.log(`Hello, ${result.data.name}!`);
  return {
    statusCode: 200,
    body: JSON.stringify({ message: `Hello, ${result.data.name}!` }),
  };
};
