<script setup>
import { computed, reactive, ref } from "vue";
import { Plus } from "@lucide/vue";
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
const { can } = useAuth(),
  { items, loading, pagination, load } = useServerTable({
    endpoint: "/api/v1/admin/suppliers",
    collectionKey: "suppliers",
  });
const open = ref(false),
  saving = ref(false),
  editing = ref(null);
const form = reactive({
  name: "",
  contact_name: "",
  phone: "",
  email: "",
  address: "",
  active: true,
});
const columns = computed(() => [
  { key: "name", label: t("supplier.name") },
  { key: "contact_name", label: t("supplier.contact") },
  { key: "phone", label: t("supplier.phone") },
  {
    key: "purchase_orders_count",
    label: t("supplier.orders"),
    sortable: false,
  },
  { key: "active", label: t("common.status") },
  { key: "action", label: t("common.action"), sortable: false },
]);
function show(item = null) {
  editing.value = item?.id || null;
  Object.assign(form, {
    name: item?.name || "",
    contact_name: item?.contact_name || "",
    phone: item?.phone || "",
    email: item?.email || "",
    address: item?.address || "",
    active: item?.active ?? true,
  });
  open.value = true;
}
async function submit() {
  saving.value = true;
  try {
    const r = await apiFetch(
      editing.value
        ? `/api/v1/admin/suppliers/${editing.value}`
        : "/api/v1/admin/suppliers",
      { method: editing.value ? "PATCH" : "POST", body: JSON.stringify(form) },
    );
    toast.success(t("supplier.saved", { name: r.supplier.name }));
    open.value = false;
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
async function remove(item) {
  if (!(await confirmToast(t("supplier.confirm_delete", { name: item.name }))))
    return;
  try {
    await apiFetch(`/api/v1/admin/suppliers/${item.id}`, { method: "DELETE" });
    await load();
  } catch (e) {
    toast.error(e.message);
  }
}
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-[1536px]">
      <div class="mb-6 flex justify-between gap-4">
        <div>
          <h1 class="text-2xl font-semibold dark:text-white">
            {{ t("supplier.title") }}
          </h1>
          <p class="text-sm text-gray-500">{{ t("supplier.subtitle") }}</p>
        </div>
        <AsyncButton
          v-if="can('suppliers.create')"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="show()"
          ><Plus :size="17" />{{ t("supplier.add") }}</AsyncButton
        >
      </div>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
        ><template #cell-active="{ item }"
          ><span class="rounded-full bg-gray-100 px-2 py-1 text-xs">{{
            t(item.active ? "common.active" : "common.inactive")
          }}</span></template
        ><template #cell-action="{ item }"
          ><div class="flex gap-2">
            <TableActionButton
              v-if="can('suppliers.update')"
              action="edit"
              :label="t('common.edit')"
              @click="show(item)"
            /><TableActionButton
              v-if="can('suppliers.delete')"
              action="delete"
              :label="t('common.delete')"
              :disabled="item.purchase_orders_count > 0"
              @click="remove(item)"
            /></div></template
      ></DataTable>
    </div>
    <AppModal
      :open="open"
      :title="t(editing ? 'supplier.edit' : 'supplier.add')"
      :close-disabled="saving"
      @close="open = false"
      ><form id="supplier-form" class="space-y-4" @submit.prevent="submit">
        <FormField :label="t('supplier.name')"
          ><TextInput v-model="form.name" required
        /></FormField>
        <div class="grid gap-3 sm:grid-cols-2">
          <FormField :label="t('supplier.contact')"
            ><TextInput v-model="form.contact_name" /></FormField
          ><FormField :label="t('supplier.phone')"
            ><TextInput v-model="form.phone"
          /></FormField>
        </div>
        <FormField :label="t('common.email')"
          ><TextInput v-model="form.email" type="email" /></FormField
        ><FormField :label="t('supplier.address')"
          ><TextareaInput v-model="form.address" rows="3" /></FormField
        ><ToggleInput v-model="form.active" :label="t('common.active')" />
      </form>
      <template #footer
        ><button @click="open = false">{{ t("common.cancel") }}</button
        ><AsyncButton
          form="supplier-form"
          type="submit"
          :loading="saving"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          >{{ t("common.save") }}</AsyncButton
        ></template
      ></AppModal
    ></AdminLayout
  >
</template>
