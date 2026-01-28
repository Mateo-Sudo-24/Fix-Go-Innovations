import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import * as braintree from "https://esm.sh/braintree@3.5.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const gateway = new braintree.BraintreeGateway({
  environment: braintree.Environment.Sandbox,
  merchantId: Deno.env.get("BRAINTREE_MERCHANT_ID")!,
  publicKey: Deno.env.get("BRAINTREE_PUBLIC_KEY")!,
  privateKey: Deno.env.get("BRAINTREE_PRIVATE_KEY")!,
});

// Configuración de cuentas para distribución de fondos
const APP_MERCHANT_ACCOUNT = Deno.env.get("APP_MERCHANT_ACCOUNT") || "fix_go_app_account";
const TECHNICIAN_MERCHANT_ACCOUNT = Deno.env.get("TECHNICIAN_MERCHANT_ACCOUNT") || "technician_payouts";

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Método no permitido", { status: 405 });
  }

  try {
    const body = await req.json();
    const { 
      nonce, 
      amount, 
      workId, 
      deviceData, 
      quotationId,
      technicianId
    } = body;

    if (!amount || !workId || !technicianId) {
      return new Response(JSON.stringify({ error: "Faltan campos requeridos: amount, workId o technicianId" }), { status: 400 });
    }

    if (!nonce) {
      return new Response(JSON.stringify({ error: "Nonce requerido para Braintree" }), { status: 400 });
    }

    // Calcular distribución: 10% para la app, 90% para el técnico
    const totalAmount = parseFloat(amount);
    const appFee = totalAmount * 0.10;
    const technicianAmount = totalAmount * 0.90;

    console.log(`💰 Procesando pago Braintree:`);
    console.log(`   Total: $${totalAmount}`);
    console.log(`   App (10%): $${appFee.toFixed(2)}`);
    console.log(`   Técnico (90%): $${technicianAmount.toFixed(2)}`);

    // Procesar pago con Braintree
    const result = await gateway.transaction.sale({
      amount: totalAmount.toString(),
      paymentMethodNonce: nonce,
      deviceData: deviceData || undefined,
      customFields: {
        work_id: workId,
        technician_id: technicianId,
      },
      options: { submitForSettlement: true },
    });

    if (!result.success) {
      console.error("❌ Error Braintree:", result.message);
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: result.message, 
          errors: result.errors 
        }),
        { status: 400 }
      );
    }

    const transaction = result.transaction;
    const transactionId = transaction.id;
    const paymentStatus = 'completed';

    const paymentMetadata = {
      transaction_id: transaction.id,
      card_type: transaction.creditCard?.cardType || (transaction.paypal ? "paypal" : "unknown"),
      app_fee: appFee.toFixed(2),
      technician_amount: technicianAmount.toFixed(2),
      timestamp: new Date().toISOString(),
    };

    console.log(`✅ Pago Braintree procesado: ${transactionId}`);

    // Actualizar accepted_works con los datos de pago
    const workUpdateData = {
      payment_method: 'braintree',
      payment_amount: totalAmount,
      app_fee: appFee,
      technician_payout: technicianAmount,
      payment_reference: transactionId,
      payment_status: paymentStatus,
      payment_metadata: paymentMetadata,
      status: 'in_progress',
      paid_at: new Date().toISOString(),
    };

    const { error: workError } = await supabase
      .from("accepted_works")
      .update(workUpdateData)
      .eq("id", workId);

    if (workError) {
      console.error("❌ Error actualizando accepted_works:", workError);
      return new Response(
        JSON.stringify({
          success: false,
          message: "Pago procesado pero error al actualizar trabajo",
          error: workError,
        }),
        { status: 500 }
      );
    }

    console.log(`✅ Trabajo actualizado: ${workId}`);

    // Cerrar la cotización
    if (quotationId) {
      const { error: quotationError } = await supabase
        .from("quotations")
        .update({ status: "accepted" })
        .eq("id", quotationId);

      if (quotationError) {
        console.warn("⚠️ Error cerrando cotización:", quotationError);
      } else {
        console.log("✅ Cotización cerrada");
      }
    }

    // Crear mensaje de confirmación en chat
    const { error: chatError } = await supabase
      .from("chat_messages")
      .insert({
        work_id: workId,
        sender_id: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
        message_text: `✅ Pago confirmado. Monto total: $${totalAmount.toFixed(2)}. El trabajo ha sido iniciado.`,
        message_type: "system",
        is_read: false,
      });

    if (chatError) {
      console.warn("⚠️ Error creando mensaje de chat:", chatError);
    } else {
      console.log("✅ Mensaje de chat creado");
    }

    // Registrar distribución de pagos
    console.log("💰 Resumen de distribución:");
    console.log(`   - App (10%): $${appFee.toFixed(2)} → ${APP_MERCHANT_ACCOUNT}`);
    console.log(`   - Técnico (90%): $${technicianAmount.toFixed(2)} → Cuenta del técnico`);

    return new Response(
      JSON.stringify({
        success: true,
        transaction_id: transactionId,
        payment_method: 'braintree',
        payment_status: paymentStatus,
        total_amount: totalAmount,
        app_fee: appFee.toFixed(2),
        technician_payout: technicianAmount.toFixed(2),
        message: "Pago procesado correctamente",
        work_id: workId,
        status: "ready_to_start",
      }),
      { status: 200 }
    );
  } catch (error) {
    console.error("❌ Error interno:", error);
    return new Response(
      JSON.stringify({ 
        error: "Error interno del servidor", 
        details: error.message 
      }),
      { status: 500 }
    );
  }
});