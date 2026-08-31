<script setup>
import { computed, reactive, ref } from "vue";
import { Plus, WalletCards } from "@lucide/vue";
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

const { can } = useAuth();
const total = ref(0);
const { items, loading, pagination, load } = useServerTable({
  endpoint: "/api/v1/admin/expenses",
  collectionKey: "expenses",
  onResponse: (r) => {
    total.value = r.summary?.total || 0;
  },
});
const modal = ref(false),
  modalLoading = ref(false),
  saving = ref(false),
  editing = ref(null);
const form = reactive({
  expense_date: new Date().toISOString().slice(0, 10),
  category: "supplies",
  description: "",
  amount: 0,
  payment_method: "cash",
  reference_number: "",
  note: "",
});
const categories = [
  "utilities",
  "transport",
  "supplies",
  "meals",
  "maintenance",
  "rent",
  "salary",
  "marketing",
  "other",
];
const payments = ["cash", "transfer", "debit_card"];
const columns = computed(() => [
  { key: "expense_date", label: t("expense.date") },
  { key: "expense_number", label: t("expense.number"), sortable: false },
  { key: "description", label: t("expense.description"), sortable: false },
  { key: "category", label: t("expense.category") },
  { key: "amount", label: t("expense.amount") },
  { key: "action", label: t("common.action"), sortable: false },
]);
const money = (value) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(value || 0);
function resetForm() {
  editing.value = null;
  Object.assign(form, {
    expense_date: new Date().toISOString().slice(0, 10),
    category: "supplies",
    description: "",
    amount: 0,
    payment_method: "cash",
    reference_number: "",
    note: "",
  });
  modal.value = true;
}
async function edit(item) {
  editing.value = item.id;
  modal.value = true;
  modalLoading.value = true;
  try {
    const r = await apiFetch(`/api/v1/admin/expenses/${item.id}`);
    Object.assign(form, r.expense);
  } catch (e) {
    toast.error(e.message);
    modal.value = false;
  } finally {
    modalLoading.value = false;
  }
}
async function submit() {
  if (!form.description.trim() || form.amount <= 0)
    return toast.error(t("validation.fix_fields"));
  saving.value = true;
  try {
    await apiFetch(
      editing.value
        ? `/api/v1/admin/expenses/${editing.value}`
        : "/api/v1/admin/expenses",
      { method: editing.value ? "PATCH" : "POST", body: JSON.stringify(form) },
    );
    toast.success(t("expense.saved"));
    modal.value = false;
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
async function remove(item) {
  if (
    !(await confirmToast(
      t("expense.confirm_delete", { number: item.expense_number }),
    ))
  )
    return;
  try {
    await apiFetch(`/api/v1/admin/expenses/${item.id}`, { method: "DELETE" });
    toast.success(t("expense.deleted"));
    await load();
  } catch (e) {
    toast.error(e.message);
  }
}
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-[1536px] space-y-6">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 class="text-2xl font-semibold dark:text-white">
            {{ t("expense.title") }}
          </h1>
          <p class="text-sm text-gray-500">{{ t("expense.subtitle") }}</p>
        </div>
        <AsyncButton
          v-if="can('expenses.create')"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="resetForm"
          ><Plus :size="17" />{{ t("expense.add") }}</AsyncButton
        >
      </div>
      <div
        class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900"
      >
        <div class="flex items-center gap-3">
          <span
            class="rounded-xl bg-brand-50 p-3 text-brand-500 dark:bg-brand-500/10"
            ><WalletCards
          /></span>
          <div>
            <p class="text-sm text-gray-500">{{ t("expense.total") }}</p>
            <p class="text-2xl font-semibold dark:text-white">
              {{ money(total) }}
            </p>
          </div>
        </div>
      </div>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
      >
        <template #cell-category="{ item }">{{
          t(`expense.category_${item.category}`)
        }}</template
        ><template #cell-amount="{ item }"
          ><span class="font-semibold">{{ money(item.amount) }}</span></template
        >
        <template #cell-action="{ item }"
          ><div class="flex gap-2">
            <TableActionButton
              v-if="can('expenses.update')"
              action="edit"
              :label="t('common.edit')"
              @click="edit(item)"
            /><TableActionButton
              v-if="can('expenses.delete')"
              action="delete"
              :label="t('common.delete')"
              @click="remove(item)"
            /></div
        ></template>
      </DataTable>
      <AppModal
        :open="modal"
        :loading="modalLoading"
        :title="t(editing ? 'expense.edit' : 'expense.add')"
        :close-disabled="saving"
        @close="modal = false"
        ><form id="expense-form" class="space-y-4" @submit.prevent="submit">
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('expense.date')"
              ><TextInput
                v-model="form.expense_date"
                type="date"
                required /></FormField
            ><FormField :label="t('expense.category')"
              ><SelectInput v-model="form.category"
                ><option
                  v-for="category in categories"
                  :key="category"
                  :value="category"
                >
                  {{ t(`expense.category_${category}`) }}
                </option></SelectInput
              ></FormField
            >
          </div>
          <FormField :label="t('expense.description')"
            ><TextInput v-model="form.description" required /></FormField
          ><FormField :label="t('expense.amount')"
            ><CurrencyInput v-model="form.amount" required
          /></FormField>
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('expense.payment_method')"
              ><SelectInput v-model="form.payment_method"
                ><option
                  v-for="method in payments"
                  :key="method"
                  :value="method"
                >
                  {{ t(`payment.${method}`) }}
                </option></SelectInput
              ></FormField
            ><FormField :label="t('expense.reference')"
              ><TextInput v-model="form.reference_number"
            /></FormField>
          </div>
          <FormField :label="t('expense.note')"
            ><TextareaInput v-model="form.note" rows="3"
          /></FormField>
        </form>
        <template #footer
          ><button @click="modal = false">{{ t("common.cancel") }}</button
          ><AsyncButton
            form="expense-form"
            type="submit"
            :loading="saving"
            class="rounded-lg bg-brand-500 px-4 py-2 text-white"
            >{{ t("common.save") }}</AsyncButton
          ></template
        ></AppModal
      >
    </div></AdminLayout
  >
</template>
