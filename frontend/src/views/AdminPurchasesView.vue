<script setup>
import { computed, reactive, ref } from "vue";
import { Plus, Printer, Trash2 } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import CurrencyInput from "../components/CurrencyInput.vue";
import DataTable from "../components/DataTable.vue";
import FormField from "../components/FormField.vue";
import SelectInput from "../components/SelectInput.vue";
import TableActionButton from "../components/TableActionButton.vue";
import TextareaInput from "../components/TextareaInput.vue";
import TextInput from "../components/TextInput.vue";
import { apiFetch } from "../services/api";
import { useAuth } from "../services/auth";
import { useServerTable } from "../services/serverTable";
import { confirmToast, toast } from "../services/toast";
import { t } from "../services/i18n";
const { can } = useAuth(),
  { items, loading, pagination, load } = useServerTable({
    endpoint: "/api/v1/admin/purchase_orders",
    collectionKey: "purchase_orders",
  });
const suppliers = ref([]),
  products = ref([]),
  modal = ref(""),
  saving = ref(false),
  detail = ref(null),
  receipt = ref(null);
const form = reactive({
    supplier_id: "",
    status: "draft",
    payment_status: "unpaid",
    notes: "",
    items: [],
  }),
  receive = reactive({ note: "", items: [] });
const columns = computed(() => [
  { key: "order_number", label: t("purchase.number") },
  { key: "supplier_name", label: t("supplier.name") },
  { key: "status", label: t("common.status") },
  { key: "payment_status", label: t("purchase.payment") },
  { key: "total", label: t("pos.total") },
  { key: "created_at", label: t("common.created_at") },
  { key: "action", label: t("common.action"), sortable: false },
]);
const money = (v) =>
    new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0,
    }).format(v || 0),
  formTotal = computed(() =>
    form.items.reduce(
      (n, x) => n + Number(x.quantity || 0) * Number(x.unit_cost || 0),
      0,
    ),
  );
function addRow() {
  form.items.push({ product_id: "", quantity: 1, unit_cost: 0 });
}
function openCreate() {
  Object.assign(form, {
    supplier_id: "",
    status: "draft",
    payment_status: "unpaid",
    notes: "",
    items: [],
  });
  addRow();
  modal.value = "create";
}
async function submit() {
  saving.value = true;
  try {
    const r = await apiFetch("/api/v1/admin/purchase_orders", {
      method: "POST",
      body: JSON.stringify(form),
    });
    toast.success(
      t("purchase.saved", { number: r.purchase_order.order_number }),
    );
    modal.value = "";
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
async function show(item) {
  modal.value = "detail";
  detail.value = null;
  try {
    const r = await apiFetch(`/api/v1/admin/purchase_orders/${item.id}`);
    detail.value = r.purchase_order;
    suppliers.value = r.suppliers;
    products.value = r.products;
  } catch (e) {
    toast.error(e.message);
    modal.value = "";
  }
}
function openReceive() {
  receive.note = "";
  receive.items = detail.value.items.map((x) => ({
    purchase_order_item_id: x.id,
    product_name: x.product_name,
    remaining: x.quantity - x.received_quantity,
    quantity: 0,
  }));
  modal.value = "receive";
}
async function submitReceive() {
  saving.value = true;
  try {
    const r = await apiFetch(
      `/api/v1/admin/purchase_orders/${detail.value.id}/receive`,
      {
        method: "POST",
        body: JSON.stringify({
          note: receive.note,
          items: receive.items.filter((x) => Number(x.quantity) > 0),
        }),
      },
    );
    receipt.value = {
      ...r.goods_receipt,
      order_number: detail.value.order_number,
    };
    detail.value = r.purchase_order;
    modal.value = "receipt";
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
async function updatePayment(value) {
  try {
    const r = await apiFetch(
      `/api/v1/admin/purchase_orders/${detail.value.id}`,
      { method: "PATCH", body: JSON.stringify({ payment_status: value }) },
    );
    detail.value = r.purchase_order;
    await load();
  } catch (e) {
    toast.error(e.message);
  }
}
async function cancelOrder() {
  if (!(await confirmToast(t("purchase.confirm_cancel")))) return;
  try {
    await apiFetch(`/api/v1/admin/purchase_orders/${detail.value.id}/cancel`, {
      method: "PATCH",
    });
    modal.value = "";
    await load();
  } catch (e) {
    toast.error(e.message);
  }
}
function print() {
  window.print();
}
async function captureOptions() {
  const r = await apiFetch("/api/v1/admin/purchase_orders?per_page=1");
  suppliers.value = r.suppliers;
  products.value = r.products;
}
captureOptions();
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-[1536px]">
      <div class="mb-6 flex justify-between">
        <div>
          <h1 class="text-2xl font-semibold dark:text-white">
            {{ t("purchase.title") }}
          </h1>
          <p class="text-sm text-gray-500">{{ t("purchase.subtitle") }}</p>
        </div>
        <AsyncButton
          v-if="can('purchases.create')"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="openCreate"
          ><Plus :size="17" />{{ t("purchase.add") }}</AsyncButton
        >
      </div>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
        ><template #cell-total="{ item }">{{ money(item.total) }}</template
        ><template #cell-created_at="{ item }">{{
          new Date(item.created_at).toLocaleDateString()
        }}</template
        ><template #cell-status="{ item }"
          ><span
            class="rounded-full bg-gray-100 px-2 py-1 text-xs capitalize"
            >{{ item.status.replaceAll("_", " ") }}</span
          ></template
        ><template #cell-action="{ item }"
          ><TableActionButton
            action="edit"
            :label="t('common.view')"
            @click="show(item)" /></template
      ></DataTable>
    </div>
    <AppModal
      :open="modal === 'create'"
      :title="t('purchase.add')"
      size="xl"
      :close-disabled="saving"
      @close="modal = ''"
      ><form id="purchase-form" class="space-y-4" @submit.prevent="submit">
        <div class="grid gap-3 sm:grid-cols-3">
          <FormField :label="t('supplier.name')"
            ><SelectInput v-model="form.supplier_id" required
              ><option value="">—</option>
              <option v-for="s in suppliers" :key="s.id" :value="s.id">
                {{ s.name }}
              </option></SelectInput
            ></FormField
          ><FormField :label="t('common.status')"
            ><SelectInput v-model="form.status"
              ><option value="draft">{{ t("common.draft") }}</option>
              <option value="ordered">
                {{ t("purchase.ordered") }}
              </option></SelectInput
            ></FormField
          ><FormField :label="t('purchase.payment')"
            ><SelectInput v-model="form.payment_status"
              ><option value="unpaid">{{ t("purchase.unpaid") }}</option>
              <option value="partial">{{ t("purchase.partial_paid") }}</option>
              <option value="paid">
                {{ t("purchase.paid") }}
              </option></SelectInput
            ></FormField
          >
        </div>
        <div class="divide-y rounded-xl border">
          <div
            v-for="(row, index) in form.items"
            :key="index"
            class="grid gap-3 p-3 sm:grid-cols-[1fr_100px_180px_40px]"
          >
            <SelectInput v-model="row.product_id"
              ><option value="">{{ t("purchase.select_product") }}</option>
              <option v-for="p in products" :key="p.id" :value="p.id">
                {{ p.name }} · {{ p.sku }}
              </option></SelectInput
            ><TextInput
              v-model.number="row.quantity"
              type="number"
              min="1"
            /><CurrencyInput v-model="row.unit_cost" /><button
              type="button"
              @click="form.items.splice(index, 1)"
            >
              <Trash2 :size="17" class="text-error-500" />
            </button>
          </div>
        </div>
        <button
          type="button"
          class="rounded border px-3 py-2 text-sm"
          @click="addRow"
        >
          + {{ t("purchase.add_item") }}</button
        ><FormField :label="t('shift.note')"
          ><TextareaInput v-model="form.notes" rows="2"
        /></FormField>
        <div class="text-right text-xl font-bold">
          {{ t("pos.total") }}: {{ money(formTotal) }}
        </div>
      </form>
      <template #footer
        ><button @click="modal = ''">{{ t("common.cancel") }}</button
        ><AsyncButton
          form="purchase-form"
          type="submit"
          :loading="saving"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          >{{ t("common.save") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
      :open="modal === 'detail'"
      :title="detail?.order_number || t('purchase.title')"
      size="xl"
      @close="modal = ''"
      ><div v-if="detail" class="purchase-print space-y-4">
        <div class="grid gap-3 sm:grid-cols-4">
          <div>
            <small>{{ t("supplier.name") }}</small>
            <p>{{ detail.supplier_name }}</p>
          </div>
          <div>
            <small>{{ t("common.status") }}</small>
            <p class="capitalize">{{ detail.status.replaceAll("_", " ") }}</p>
          </div>
          <div>
            <small>{{ t("purchase.payment") }}</small
            ><SelectInput
              v-if="can('purchases.update')"
              :model-value="detail.payment_status"
              @update:model-value="updatePayment"
              ><option value="unpaid">{{ t("purchase.unpaid") }}</option>
              <option value="partial">{{ t("purchase.partial_paid") }}</option>
              <option value="paid">
                {{ t("purchase.paid") }}
              </option></SelectInput
            >
            <p v-else>{{ detail.payment_status }}</p>
          </div>
          <div>
            <small>{{ t("pos.total") }}</small>
            <p class="font-bold">{{ money(detail.total) }}</p>
          </div>
        </div>
        <div class="divide-y rounded-xl border">
          <div
            v-for="i in detail.items"
            :key="i.id"
            class="grid grid-cols-[1fr_auto] gap-3 p-3"
          >
            <span
              >{{ i.product_name }} · {{ i.sku
              }}<small class="block text-gray-500"
                >{{ i.received_quantity }} / {{ i.quantity }}
                {{ t("purchase.received") }}</small
              ></span
            ><b>{{ money(i.subtotal) }}</b>
          </div>
        </div>
        <div class="flex flex-wrap gap-2 print:hidden">
          <AsyncButton class="rounded border px-3 py-2" @click="print"
            ><Printer :size="16" />{{ t("report.print") }}</AsyncButton
          ><AsyncButton
            v-if="
              can('purchases.update') &&
              ['ordered', 'partially_received'].includes(detail.status)
            "
            class="rounded bg-brand-500 px-3 py-2 text-white"
            @click="openReceive"
            >{{ t("purchase.receive") }}</AsyncButton
          ><AsyncButton
            v-if="
              can('purchases.update') &&
              ['draft', 'ordered'].includes(detail.status) &&
              !detail.received_count
            "
            class="rounded bg-error-600 px-3 py-2 text-white"
            @click="cancelOrder"
            >{{ t("purchase.cancel") }}</AsyncButton
          >
        </div>
      </div></AppModal
    >
    <AppModal
      :open="modal === 'receive'"
      :title="t('purchase.receive')"
      @close="modal = 'detail'"
      ><form
        id="receive-form"
        class="space-y-3"
        @submit.prevent="submitReceive"
      >
        <label
          v-for="row in receive.items"
          :key="row.purchase_order_item_id"
          class="flex items-center justify-between gap-3 rounded-lg border p-3"
          ><span
            >{{ row.product_name
            }}<small class="block text-gray-500"
              >{{ t("purchase.remaining") }} {{ row.remaining }}</small
            ></span
          ><TextInput
            v-model.number="row.quantity"
            type="number"
            min="0"
            :max="row.remaining"
            class="w-24" /></label
        ><TextareaInput
          v-model="receive.note"
          rows="2"
          :placeholder="t('shift.note')"
        />
      </form>
      <template #footer
        ><AsyncButton
          form="receive-form"
          type="submit"
          :loading="saving"
          class="rounded bg-brand-500 px-4 py-2 text-white"
          >{{ t("purchase.receive") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
      :open="modal === 'receipt'"
      :title="receipt?.receipt_number || t('purchase.receipt')"
      @close="modal = 'detail'"
      ><article
        v-if="receipt"
        class="thermal-purchase receipt-58 mx-auto bg-white p-3 font-mono text-xs text-black"
      >
        <h2 class="text-center font-bold">{{ t("purchase.receipt") }}</h2>
        <p class="text-center">
          {{ receipt.receipt_number }}<br />{{ receipt.order_number }}
        </p>
        <hr class="my-2" />
        <div
          v-for="i in receipt.items"
          :key="i.purchase_order_item_id"
          class="flex justify-between"
        >
          <span>#{{ i.purchase_order_item_id }}</span
          ><b>× {{ i.quantity }}</b>
        </div>
        <p class="mt-3">{{ receipt.note }}</p>
      </article>
      <template #footer
        ><AsyncButton
          class="rounded bg-brand-500 px-4 py-2 text-white"
          @click="print"
          ><Printer :size="16" />{{ t("report.print") }}</AsyncButton
        ></template
      ></AppModal
    ></AdminLayout
  >
</template>
<style>
.receipt-58 {
  width: 58mm;
}
@media print {
  body * {
    visibility: hidden !important;
  }
  .purchase-print,
  .purchase-print *,
  .thermal-purchase,
  .thermal-purchase * {
    visibility: visible !important;
  }
  .purchase-print,
  .thermal-purchase {
    position: absolute;
    inset: 0 auto auto 0;
  }
}
</style>
