import { createClient } from "https://esm.sh/@supabase/supabase-js@2.50.0";

export async function handler(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseKey);

  const { error, data } = await supabase
    .from("appointments")
    .update({ provider_id: "7c014c7c-f96e-4e47-905d-1929cbd33790" })
    .eq("id", "8101feee-9bd4-4b44-b618-775b7192324a")
    .select();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true, data }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(handler);
