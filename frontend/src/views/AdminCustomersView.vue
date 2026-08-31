<script setup>
import { computed, reactive, ref } from "vue";
import { Plus, Star } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import DataTable from "../components/DataTable.vue";
import FormField from "../components/FormField.vue";
import TableActionButton from "../components/TableActionButton.vue";
import TextareaInput from "../components/TextareaInput.vue";
import TextInput from "../components/TextInput.vue";
import ToggleInput from "../components/ToggleInput.vue";
import { apiFetch } from "../services/api";
import { useAuth } from "../services/auth";
import { useServerTable } from "../services/serverTable";
import { confirmToast, toast } from "../services/toast";
import { t } from "../services/i18n";
const { can } = useAuth();
const { items, loading, pagination, load } = useServerTable({
  endpoint: "/api/v1/admin/customers",
  collectionKey: "customers",
});
const open = ref(false),
  modalLoading = ref(false),
  saving = ref(false),
  editing = ref(null),
  recentSales = ref([]);
const form = reactive({
  name: "",
  phone: "",
  email: "",
  address: "",
  member: false,
  active: true,
});
const columns = computed(() => [
  { key: "customer_number", label: t("customer.number"), sortable: false },
  { key: "name", label: t("customer.name") },
  { key: "phone", label: t("customer.whatsapp"), sortable: false },
  { key: "member", label: t("customer.membership") },
  { key: "points", label: t("customer.points") },
  { key: "total_spent", label: t("customer.spent"), sortable: false },
  { key: "action", label: t("common.action"), sortable: false },
]);
const money = (v) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(v || 0);
function createCustomer() {
  editing.value = null;
  recentSales.value = [];
  Object.assign(form, {
    name: "",
    phone: "",
    email: "",
    address: "",
    member: false,
    active: true,
  });
  open.value = true;
}
async function edit(item) {
  editing.value = item.id;
  open.value = true;
  modalLoading.value = true;
  try {
    const r = await apiFetch(`/api/v1/admin/customers/${item.id}`);
    Object.assign(form, r.customer);
    recentSales.value = r.customer.recent_sales || [];
  } catch (e) {
    toast.error(e.message);
    open.value = false;
  } finally {
    modalLoading.value = false;
  }
}
async function submit() {
  if (!form.name.trim()) return toast.error(t("validation.fix_fields"));
  saving.value = true;
  try {
    await apiFetch(
      editing.value
        ? `/api/v1/admin/customers/${editing.value}`
        : "/api/v1/admin/customers",
      { method: editing.value ? "PATCH" : "POST", body: JSON.stringify(form) },
    );
    toast.success(t("customer.saved"));
    open.value = false;
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
async function remove(item) {
  if (!(await confirmToast(t("customer.confirm_delete", { name: item.name }))))
    return;
  try {
    await apiFetch(`/api/v1/admin/customers/${item.id}`, { method: "DELETE" });
    toast.success(t("customer.deleted"));
    await load();
  } catch (e) {
    toast.error(e.message);
  }
}
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-[1536px] space-y-6">
      <div class="flex flex-wrap justify-between gap-4">
        <div>
          <h1 class="text-2xl font-semibold dark:text-white">
            {{ t("customer.title") }}
          </h1>
          <p class="text-sm text-gray-500">{{ t("customer.subtitle") }}</p>
        </div>
        <AsyncButton
          v-if="can('customers.create')"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="createCustomer"
          ><Plus :size="17" />{{ t("customer.add") }}</AsyncButton
        >
      </div>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
        ><template #cell-member="{ item }"
          ><span
            class="inline-flex items-center gap-1 rounded-full bg-gray-100 px-2 py-1 text-xs dark:bg-gray-800"
            ><Star v-if="item.member" :size="13" />{{
              t(item.member ? "customer.member" : "customer.regular")
            }}</span
          ></template
        ><template #cell-total_spent="{ item }">{{
          money(item.total_spent)
        }}</template
        ><template #cell-action="{ item }"
          ><div class="flex gap-2">
            <TableActionButton
              action="view"
              :label="t('common.view')"
              @click="edit(item)"
            /><TableActionButton
              v-if="can('customers.delete')"
              action="delete"
              :label="t('common.delete')"
              :disabled="item.sales_count > 0"
              @click="remove(item)"
            /></div></template
      ></DataTable>
      <AppModal
        :open="open"
        :loading="modalLoading"
        :title="t(editing ? 'customer.edit' : 'customer.add')"
        size="lg"
        :close-disabled="saving"
        @close="open = false"
        ><form id="customer-form" class="space-y-4" @submit.prevent="submit">
          <FormField :label="t('customer.name')"
            ><TextInput v-model="form.name" required
          /></FormField>
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('customer.whatsapp')"
              ><TextInput v-model="form.phone" /></FormField
            ><FormField :label="t('common.email')"
              ><TextInput v-model="form.email" type="email"
            /></FormField>
          </div>
          <FormField :label="t('customer.address')"
            ><TextareaInput v-model="form.address" rows="2"
          /></FormField>
          <div class="grid gap-3 sm:grid-cols-2">
            <ToggleInput
              v-model="form.member"
              :label="t('customer.member')"
            /><ToggleInput v-model="form.active" :label="t('common.active')" />
          </div>
        </form>
        <div v-if="editing" class="mt-6 border-t pt-4">
          <h3 class="font-semibold dark:text-white">
            {{ t("customer.history") }}
          </h3>
          <p v-if="!recentSales.length" class="mt-3 text-sm text-gray-500">
            {{ t("customer.no_history") }}
          </p>
          <div v-else class="mt-2 divide-y">
            <div
              v-for="sale in recentSales"
              :key="sale.id"
              class="flex justify-between py-2 text-sm"
            >
              <span
                >{{ sale.sale_number
                }}<small class="block text-gray-500">{{
                  new Date(sale.completed_at).toLocaleString()
                }}</small></span
              ><b>{{ money(sale.total) }}</b>
            </div>
          </div>
        </div>
        <template #footer
          ><button @click="open = false">{{ t("common.cancel") }}</button
          ><AsyncButton
            v-if="!editing || can('customers.update')"
            form="customer-form"
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
