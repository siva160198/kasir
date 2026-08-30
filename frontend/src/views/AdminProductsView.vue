<script setup>
import { computed, reactive, ref } from "vue";
import { Plus, Save } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import DataTable from "../components/DataTable.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import FormField from "../components/FormField.vue";
import TextInput from "../components/TextInput.vue";
import CurrencyInput from "../components/CurrencyInput.vue";
import SelectInput from "../components/SelectInput.vue";
import ToggleInput from "../components/ToggleInput.vue";
import TableActionButton from "../components/TableActionButton.vue";
import { apiFetch } from "../services/api";
import { hasChanges, snapshot } from "../services/changeTracking";
import { useFormErrors } from "../services/formErrors";
import { t } from "../services/i18n";
import { useServerTable } from "../services/serverTable";
import { confirmToast, toast } from "../services/toast";
import { useAuth } from "../services/auth";

const { can, canAny } = useAuth();
const categories = ref([]);
const modalOpen = ref(false);
const modalLoading = ref(false);
const saving = ref(false);
const deletingIds = ref(new Set());
const editingId = ref(null);
const original = ref(null);
const formElement = ref(null);
const errors = useFormErrors();
let requestSequence = 0;
const blank = () => ({ category_id: "", name: "", sku: "", barcode: "", cost_price: 0, selling_price: 0, minimum_stock: 0, unit: "pcs", active: true });
const form = reactive(blank());
const { items, loading, pagination, load, updateItem, removeItem } = useServerTable({ endpoint: "/api/v1/admin/products", collectionKey: "products", onResponse: (response) => { categories.value = response.categories || categories.value; } });
const columns = computed(() => [
  { key: "name", label: t("products.name") }, { key: "sku", label: t("products.sku") },
  { key: "category_name", label: t("products.category"), sortable: false }, { key: "selling_price", label: t("products.selling_price") },
  { key: "minimum_stock", label: t("products.minimum_stock") }, { key: "active", label: t("common.status") },
  { key: "action", label: t("common.action"), sortable: false },
]);
const changed = computed(() => !editingId.value || hasChanges(form, original.value));
const rupiah = (value) => new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(value || 0);

function setForm(product = null) { Object.assign(form, blank(), product || {}); form.category_id = product?.category_id || ""; original.value = product ? snapshot(form) : null; }
function openCreate() { editingId.value = null; setForm(); errors.clearErrors(); modalOpen.value = true; }
async function openEdit(product) {
  const sequence = ++requestSequence; editingId.value = product.id; setForm(product); errors.clearErrors(); modalOpen.value = true; modalLoading.value = true;
  try { const response = await apiFetch(`/api/v1/admin/products/${product.id}`); if (sequence !== requestSequence) return; categories.value = response.categories; setForm(response.product); }
  catch (error) { if (sequence === requestSequence) { toast.error(error.message); closeModal(true); } }
  finally { if (sequence === requestSequence) modalLoading.value = false; }
}
function closeModal(force = false) { if ((modalLoading.value || saving.value) && !force) return; requestSequence += 1; modalOpen.value = false; editingId.value = null; errors.clearErrors(); }
async function submit() {
  const nonnegative = (value) => Number.isInteger(Number(value)) && Number(value) >= 0;
  const valid = await errors.validate({
    category_id: () => form.category_id ? "" : t("validation.required"), name: () => form.name.trim() ? "" : t("validation.required"), sku: () => form.sku.trim() ? "" : t("validation.required"),
    cost_price: () => nonnegative(form.cost_price) ? "" : t("validation.nonnegative_integer"), selling_price: () => nonnegative(form.selling_price) ? "" : t("validation.nonnegative_integer"), minimum_stock: () => nonnegative(form.minimum_stock) ? "" : t("validation.nonnegative_integer"), unit: () => form.unit.trim() ? "" : t("validation.required"),
  }, formElement.value);
  if (!valid) { toast.warning(t("validation.fix_fields")); return; }
  saving.value = true;
  try {
    const payload = { ...form, category_id: Number(form.category_id), cost_price: Number(form.cost_price), selling_price: Number(form.selling_price), minimum_stock: Number(form.minimum_stock) };
    const response = await apiFetch(editingId.value ? `/api/v1/admin/products/${editingId.value}` : "/api/v1/admin/products", { method: editingId.value ? "PATCH" : "POST", body: JSON.stringify(payload) });
    if (editingId.value) updateItem(editingId.value, response.product); else await load();
    toast.success(t(editingId.value ? "products.updated" : "products.created", { name: response.product.name })); closeModal(true);
  } catch (error) { await errors.applyApiError(error, formElement.value); toast.error(error.message); }
  finally { saving.value = false; }
}
async function destroyProduct(product) {
  if (!(await confirmToast(t("products.confirm_delete", { name: product.name }), { confirmLabel: t("common.delete") }))) return;
  deletingIds.value = new Set(deletingIds.value).add(product.id);
  try { await apiFetch(`/api/v1/admin/products/${product.id}`, { method: "DELETE" }); removeItem(product.id); toast.success(t("products.deleted", { name: product.name })); }
  catch (error) { toast.error(error.message); }
  finally { const next = new Set(deletingIds.value); next.delete(product.id); deletingIds.value = next; }
}
</script>

<template><AdminLayout><div class="mx-auto max-w-[1536px]">
  <div class="mb-6 flex items-start justify-between gap-4"><div><h1 class="text-2xl font-semibold text-gray-900 dark:text-white">{{ t('products.title') }}</h1><p class="mt-1 text-sm text-gray-500">{{ t('products.subtitle') }}</p></div><AsyncButton v-if="can('products.create')" :loading="false" class="rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white" @click="openCreate"><Plus :size="17" />{{ t('products.add') }}</AsyncButton></div>
  <DataTable :items="items" :columns="columns" :loading="loading" :empty-text="t('products.empty')" server-mode :total="pagination.total" @request="load">
    <template #cell-name="{ item }"><span class="font-medium text-gray-900 dark:text-white">{{ item.name }}</span><small v-if="item.barcode" class="block text-gray-400">{{ item.barcode }}</small></template>
    <template #cell-sku="{ item }"><span class="font-mono text-xs">{{ item.sku }}</span></template><template #cell-selling_price="{ item }">{{ rupiah(item.selling_price) }}</template>
    <template #cell-active="{ item }"><span :class="item.active ? 'bg-brand-50 text-brand-600' : 'bg-gray-100 text-gray-500'" class="rounded-full px-2.5 py-1 text-xs font-medium">{{ t(item.active ? 'common.active' : 'common.inactive') }}</span></template>
    <template #cell-action="{ item }"><div v-if="canAny(['products.update','products.delete'])" class="flex gap-2"><TableActionButton v-if="can('products.update')" action="edit" :label="t('common.edit')" :accessible-label="t('products.edit_item', { name: item.name })" @click="openEdit(item)" /><TableActionButton v-if="can('products.delete')" action="delete" :label="t('common.delete')" :accessible-label="t('products.delete_item', { name: item.name })" :loading="deletingIds.has(item.id)" @click="destroyProduct(item)" /></div><span v-else class="text-xs text-gray-400">{{ t('common.view_only') }}</span></template>
  </DataTable>
 </div>
 <AppModal :open="modalOpen" :title="t(editingId ? 'products.edit_title' : 'products.create_title')" :loading="modalLoading" :close-disabled="saving" size="xl" @close="closeModal">
  <form ref="formElement" id="product-form" class="grid gap-5 md:grid-cols-2" novalidate @submit.prevent="submit">
    <FormField :label="t('products.category')" :error="errors.errorFor('category_id')"><SelectInput v-model="form.category_id" name="category_id" :disabled="saving" @change="errors.clearError('category_id')"><option value="">{{ t('products.select_category') }}</option><option v-for="category in categories" :key="category.id" :value="category.id">{{ category.name }}</option></SelectInput></FormField>
    <FormField :label="t('products.name')" :error="errors.errorFor('name')"><TextInput v-model="form.name" name="name" :disabled="saving" @input="errors.clearError('name')" /></FormField>
    <FormField :label="t('products.sku')" :error="errors.errorFor('sku')"><TextInput v-model="form.sku" name="sku" :disabled="saving" @input="errors.clearError('sku')" /></FormField>
    <FormField :label="t('products.barcode')" :error="errors.errorFor('barcode')"><TextInput v-model="form.barcode" name="barcode" :disabled="saving" @input="errors.clearError('barcode')" /></FormField>
    <FormField :label="t('products.cost_price')" :error="errors.errorFor('cost_price')"><CurrencyInput v-model="form.cost_price" name="cost_price" :disabled="saving" @input="errors.clearError('cost_price')" /></FormField>
    <FormField :label="t('products.selling_price')" :error="errors.errorFor('selling_price')"><CurrencyInput v-model="form.selling_price" name="selling_price" :disabled="saving" @input="errors.clearError('selling_price')" /></FormField>
    <FormField :label="t('products.minimum_stock')" :error="errors.errorFor('minimum_stock')"><TextInput v-model="form.minimum_stock" name="minimum_stock" type="number" min="0" :disabled="saving" @input="errors.clearError('minimum_stock')" /></FormField>
    <FormField :label="t('products.unit')" :error="errors.errorFor('unit')"><TextInput v-model="form.unit" name="unit" :disabled="saving" @input="errors.clearError('unit')" /></FormField>
    <ToggleInput v-model="form.active" class="md:col-span-2" :label="t('common.active')" :hint="t('products.active_hint')" :disabled="saving" />
  </form>
  <template #footer><button type="button" class="rounded-lg border border-gray-200 px-4 py-2.5 text-sm font-semibold" :disabled="saving" @click="closeModal">{{ t('common.cancel') }}</button><AsyncButton form="product-form" type="submit" :loading="saving" :disabled="editingId && !changed" :loading-text="t('common.saving')" class="rounded-lg bg-brand-500 px-5 py-2.5 text-sm font-semibold text-white"><Save :size="16" />{{ t('common.save') }}</AsyncButton></template>
 </AppModal></AdminLayout></template>
