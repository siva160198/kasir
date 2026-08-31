<script setup>
import { computed, reactive, ref } from "vue";
import { Printer } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import DataTable from "../components/DataTable.vue";
import TableActionButton from "../components/TableActionButton.vue";
import TextareaInput from "../components/TextareaInput.vue";
import TextInput from "../components/TextInput.vue";
import { apiFetch } from "../services/api";
import { useAuth } from "../services/auth";
import { toast } from "../services/toast";
import { useServerTable } from "../services/serverTable";
import { t } from "../services/i18n";
const { items, loading, pagination, load } = useServerTable({
  endpoint: "/api/v1/admin/sales",
  collectionKey: "sales",
});
const columns = computed(() => [
  { key: "sale_number", label: t("sales.number") },
  { key: "completed_at", label: t("sales.time") },
  { key: "user_email", label: t("sales.cashier"), sortable: false },
  { key: "item_count", label: t("sales.items"), sortable: false },
  { key: "payment_method", label: t("sales.payment"), sortable: false },
  { key: "total", label: t("pos.total") },
  { key: "status", label: t("sales.status") },
  { key: "action", label: t("common.action"), sortable: false },
]);
const detail = ref(null);
const detailLoading = ref(false);
const refundMode = ref("");
const refundSaving = ref(false);
const refundReceipt = ref(null);
const refundForm = reactive({ reason: "", reviewNote: "" });
const { can } = useAuth();
let detailSequence = 0;
async function showDetail(item) {
  const sequence = ++detailSequence;
  detail.value = { id: item.id, sale_number: item.sale_number };
  detailLoading.value = true;
  try {
    const response = await apiFetch(`/api/v1/admin/sales/${item.id}`);
    if (sequence === detailSequence) {
      detail.value = response.sale;
      resetRefundForm();
    }
  } catch (error) {
    if (sequence === detailSequence) {
      detail.value = null;
      toast.error(error.message);
    }
  } finally {
    if (sequence === detailSequence) detailLoading.value = false;
  }
}
function resetRefundForm() {
  refundMode.value = "";
  refundForm.reason = "";
  refundForm.reviewNote = "";
  detail.value?.items?.forEach((item) => (item.return_quantity = 0));
}
async function requestRefund(type) {
  if (refundMode.value !== type) {
    refundMode.value = type;
    return;
  }
  refundSaving.value = true;
  try {
    const body = { refund_type: type, reason: refundForm.reason };
    if (type === "partial")
      body.items = detail.value.items
        .map((item) => ({
          sale_item_id: item.id,
          quantity: Number(item.return_quantity || 0),
        }))
        .filter((item) => item.quantity > 0);
    const response = await apiFetch(
      `/api/v1/admin/sales/${detail.value.id}/refunds`,
      { method: "POST", body: JSON.stringify(body) },
    );
    toast.success(
      t("refund.created", { number: response.refund.refund_number }),
    );
    await showDetail(detail.value);
    await load();
  } catch (error) {
    toast.error(error.message);
  } finally {
    refundSaving.value = false;
  }
}
async function reviewRefund(refund, action) {
  refundSaving.value = true;
  try {
    const response = await apiFetch(
      `/api/v1/admin/sale_refunds/${refund.id}/${action}`,
      {
        method: "PATCH",
        body: JSON.stringify({ review_note: refundForm.reviewNote }),
      },
    );
    toast.success(t("refund.reviewed"));
    if (action === "approve")
      refundReceipt.value = {
        ...response.refund,
        sale_number: detail.value.sale_number,
      };
    await showDetail(detail.value);
    await load();
  } catch (error) {
    toast.error(error.message);
  } finally {
    refundSaving.value = false;
  }
}
const refundStatus = (status) => t(`refund.${status}`);
const printRefund = () => window.print();
function closeDetail() {
  if (detailLoading.value) return;
  detailSequence += 1;
  detail.value = null;
}
const printSale = () => window.print();
const money = (v) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(v || 0);
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-[1536px]">
      <h1 class="mb-6 text-2xl font-semibold dark:text-white">
        {{ t("sales.title") }}
      </h1>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
        ><template #cell-completed_at="{ item }">{{
          new Date(item.completed_at).toLocaleString()
        }}</template
        ><template #cell-total="{ item }">{{ money(item.total) }}</template
        ><template #cell-status="{ item }"
          ><span
            class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold capitalize dark:bg-gray-800"
            >{{ item.status.replaceAll("_", " ") }}</span
          ></template
        ><template #cell-payment_method="{ item }">{{
          item.payment_method
        }}</template
        ><template #cell-action="{ item }"
          ><TableActionButton
            action="edit"
            :label="t('common.view')"
            :accessible-label="`${t('common.view')} ${item.sale_number}`"
            @click="showDetail(item)" /></template
      ></DataTable>
    </div>
    <AppModal
      :open="Boolean(detail)"
      :title="detail?.sale_number || t('sales.title')"
      :loading="detailLoading"
      size="xl"
      @close="closeDetail"
      ><div v-if="detail?.items" class="space-y-5">
        <div class="grid gap-3 sm:grid-cols-3">
          <div>
            <small class="text-gray-500">{{ t("sales.cashier") }}</small>
            <p>{{ detail.user_email }}</p>
          </div>
          <div>
            <small class="text-gray-500">{{ t("sales.payment") }}</small>
            <p v-for="payment in detail.payments" :key="payment.id">
              {{ payment.payment_method }} · {{ money(payment.amount) }}
              {{ payment.reference_number || "" }}
            </p>
          </div>
          <div>
            <small class="text-gray-500">{{ t("pos.total") }}</small>
            <p class="font-bold">{{ money(detail.total) }}</p>
          </div>
        </div>
        <div class="divide-y rounded-xl border">
          <div
            v-for="item in detail.items"
            :key="item.id"
            class="flex justify-between p-3"
          >
            <span
              >{{ item.product_name }} × {{ item.quantity
              }}<small v-if="item.refunded_quantity" class="ml-2 text-error-500"
                >({{ item.refunded_quantity }} retur)</small
              ></span
            ><span>{{ money(item.subtotal) }}</span>
          </div>
        </div>
        <section
          v-if="
            can('sales.refund_create') &&
            !['refunded', 'voided'].includes(detail.status)
          "
          class="rounded-xl border p-4"
        >
          <h3 class="font-semibold">{{ t("refund.title") }}</h3>
          <div class="mt-3 flex flex-wrap gap-2">
            <button
              class="rounded-lg border px-3 py-2 text-sm font-semibold"
              :class="
                refundMode === 'partial'
                  ? 'border-brand-500 bg-brand-50 text-brand-700'
                  : ''
              "
              @click="requestRefund('partial')"
            >
              {{ t("refund.partial") }}
            </button>
            <button
              class="rounded-lg border border-error-300 px-3 py-2 text-sm font-semibold text-error-600"
              :class="refundMode === 'void' ? 'bg-error-50' : ''"
              @click="requestRefund('void')"
            >
              {{ t("refund.void") }}
            </button>
          </div>
          <div v-if="refundMode" class="mt-4 space-y-3">
            <div
              v-if="refundMode === 'partial'"
              class="divide-y rounded-lg border"
            >
              <label
                v-for="item in detail.items.filter(
                  (row) => row.refundable_quantity > 0,
                )"
                :key="item.id"
                class="flex items-center justify-between gap-3 p-3 text-sm"
              >
                <span
                  >{{ item.product_name }}
                  <small class="text-gray-500"
                    >maks. {{ item.refundable_quantity }}</small
                  ></span
                >
                <TextInput
                  v-model.number="item.return_quantity"
                  type="number"
                  min="0"
                  :max="item.refundable_quantity"
                  class="w-24"
                />
              </label>
            </div>
            <TextareaInput
              v-model="refundForm.reason"
              rows="2"
              :placeholder="t('refund.reason')"
            />
            <AsyncButton
              :loading="refundSaving"
              class="rounded-lg bg-brand-500 px-4 py-2 text-white"
              @click="requestRefund(refundMode)"
              >{{ t("refund.submit") }}</AsyncButton
            >
          </div>
        </section>
        <section>
          <h3 class="mb-3 font-semibold">{{ t("refund.history") }}</h3>
          <p v-if="!detail.refunds.length" class="text-sm text-gray-500">
            {{ t("refund.empty") }}
          </p>
          <div
            v-for="refund in detail.refunds"
            :key="refund.id"
            class="mb-3 rounded-xl border p-4"
          >
            <div class="flex flex-wrap items-start justify-between gap-2">
              <div>
                <strong>{{ refund.refund_number }}</strong>
                <p class="text-sm text-gray-500">{{ refund.reason }}</p>
              </div>
              <div class="text-right">
                <span
                  class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold dark:bg-gray-800"
                  >{{ refundStatus(refund.status) }}</span
                >
                <p class="mt-2 font-bold">{{ money(refund.total) }}</p>
              </div>
            </div>
            <div class="mt-2 text-xs text-gray-500">
              {{ refund.requested_by }} ·
              {{ new Date(refund.created_at).toLocaleString() }}
            </div>
            <div
              v-if="refund.status === 'pending' && can('sales.refund_review')"
              class="mt-3 space-y-2 border-t pt-3"
            >
              <TextareaInput
                v-model="refundForm.reviewNote"
                rows="2"
                :placeholder="t('refund.review_note')"
              />
              <div class="flex gap-2">
                <AsyncButton
                  :loading="refundSaving"
                  class="rounded-lg bg-brand-500 px-3 py-2 text-sm text-white"
                  @click="reviewRefund(refund, 'approve')"
                  >{{ t("refund.approve") }}</AsyncButton
                ><AsyncButton
                  :disabled="refundSaving"
                  class="rounded-lg border border-error-300 px-3 py-2 text-sm text-error-600"
                  @click="reviewRefund(refund, 'reject')"
                  >{{ t("refund.reject") }}</AsyncButton
                >
              </div>
            </div>
          </div>
        </section>
        <article
          class="thermal-sale receipt-58 hidden bg-white p-3 font-mono text-xs text-black print:block"
        >
          <h2 class="text-center text-lg font-bold">
            {{ t("receipt.store") }}
          </h2>
          <p class="text-center">
            {{ detail.sale_number }}<br />{{
              new Date(detail.completed_at).toLocaleString()
            }}
          </p>
          <hr class="my-2" />
          <div v-for="item in detail.items" :key="item.id">
            <div>{{ item.product_name }}</div>
            <div class="flex justify-between">
              <span>{{ item.quantity }} × {{ money(item.unit_price) }}</span
              ><span>{{ money(item.subtotal) }}</span>
            </div>
            <div v-if="item.discount" class="flex justify-between">
              <span>{{ t("pos.item_discount") }}</span
              ><span>-{{ money(item.discount) }}</span>
            </div>
          </div>
          <hr class="my-2" />
          <div v-if="detail.discount" class="flex justify-between">
            <span>{{ t("pos.discount") }}</span
            ><span>-{{ money(detail.discount) }}</span>
          </div>
          <div class="flex justify-between font-bold">
            <span>{{ t("pos.total") }}</span
            ><span>{{ money(detail.total) }}</span>
          </div>
          <p v-if="detail.customer_name" class="mt-2">
            {{ t("customer.title") }}: {{ detail.customer_name }}
          </p>
          <div
            v-for="payment in detail.payments"
            :key="payment.id"
            class="flex justify-between"
          >
            <span>{{ payment.payment_method }}</span
            ><span>{{ money(payment.amount) }}</span>
          </div>
        </article>
      </div>
      <template #footer
        ><AsyncButton
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="printSale"
          ><Printer :size="16" />{{ t("pos.reprint") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
      :open="Boolean(refundReceipt)"
      :title="refundReceipt?.refund_number || t('refund.receipt')"
      @close="refundReceipt = null"
    >
      <article
        v-if="refundReceipt"
        class="thermal-refund receipt-58 mx-auto bg-white p-3 font-mono text-xs text-black"
      >
        <h2 class="text-center text-lg font-bold">{{ t("refund.receipt") }}</h2>
        <p class="text-center">
          {{ refundReceipt.refund_number }}<br />{{ refundReceipt.sale_number }}
        </p>
        <hr class="my-2" />
        <div v-for="item in refundReceipt.items" :key="item.id">
          <div>{{ item.product_name }}</div>
          <div class="flex justify-between">
            <span>{{ item.quantity }} × {{ money(item.unit_price) }}</span
            ><span>{{ money(item.subtotal) }}</span>
          </div>
        </div>
        <hr class="my-2" />
        <div class="flex justify-between font-bold">
          <span>{{ t("pos.total") }}</span
          ><span>{{ money(refundReceipt.total) }}</span>
        </div>
        <p class="mt-3 text-center">{{ refundReceipt.reason }}</p>
      </article>
      <template #footer
        ><AsyncButton
          class="rounded bg-brand-500 px-4 py-2 text-white"
          @click="printRefund"
          ><Printer :size="16" />{{ t("pos.print") }}</AsyncButton
        ></template
      >
    </AppModal>
  </AdminLayout>
</template>
<style>
.receipt-58 {
  width: 58mm;
}
@media print {
  body * {
    visibility: hidden !important;
  }
  .thermal-refund,
  .thermal-refund *,
  .thermal-sale,
  .thermal-sale * {
    visibility: visible !important;
  }
  .thermal-refund,
  .thermal-sale {
    position: fixed;
    inset: 0 auto auto 0;
    display: block !important;
  }
}
</style>
