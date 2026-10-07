export const handler = async (event) => {
  console.log("Hello, World!");
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello, World!" }),
  };
};
