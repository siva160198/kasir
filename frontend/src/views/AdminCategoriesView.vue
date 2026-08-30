<script setup>
import { computed, reactive, ref } from "vue";
import { Plus, Save } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import DataTable from "../components/DataTable.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import FormField from "../components/FormField.vue";
import TextInput from "../components/TextInput.vue";
import TextareaInput from "../components/TextareaInput.vue";
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
const modalOpen = ref(false);
const modalLoading = ref(false);
const saving = ref(false);
const deletingIds = ref(new Set());
const editingId = ref(null);
const original = ref(null);
const formElement = ref(null);
const errors = useFormErrors();
let requestSequence = 0;
const form = reactive({ name: "", description: "", active: true });
const { items, loading, pagination, load, updateItem, removeItem } = useServerTable({ endpoint: "/api/v1/admin/categories", collectionKey: "categories" });
const columns = computed(() => [
  { key: "name", label: t("categories.name") },
  { key: "description", label: t("categories.description"), sortable: false },
  { key: "products_count", label: t("categories.products_count"), sortable: false },
  { key: "active", label: t("common.status") },
  { key: "action", label: t("common.action"), sortable: false },
]);
const changed = computed(() => !editingId.value || hasChanges(form, original.value));

function resetForm(category = null) {
  Object.assign(form, { name: category?.name || "", description: category?.description || "", active: category?.active ?? true });
  original.value = category ? snapshot(form) : null;
}

function openCreate() { editingId.value = null; resetForm(); errors.clearErrors(); modalOpen.value = true; }
async function openEdit(category) {
  const sequence = ++requestSequence;
  editingId.value = category.id; resetForm(category); errors.clearErrors(); modalOpen.value = true; modalLoading.value = true;
  try {
    const response = await apiFetch(`/api/v1/admin/categories/${category.id}`);
    if (sequence !== requestSequence) return;
    resetForm(response.category);
  } catch (error) { if (sequence === requestSequence) { toast.error(error.message); closeModal(true); } }
  finally { if (sequence === requestSequence) modalLoading.value = false; }
}
function closeModal(force = false) { if ((modalLoading.value || saving.value) && !force) return; requestSequence += 1; modalOpen.value = false; editingId.value = null; errors.clearErrors(); }
async function submit() {
  const valid = await errors.validate({ name: () => form.name.trim() ? "" : t("validation.required") }, formElement.value);
  if (!valid) { toast.warning(t("validation.fix_fields")); return; }
  saving.value = true;
  try {
    const response = await apiFetch(editingId.value ? `/api/v1/admin/categories/${editingId.value}` : "/api/v1/admin/categories", { method: editingId.value ? "PATCH" : "POST", body: JSON.stringify(form) });
    if (editingId.value) updateItem(editingId.value, response.category); else await load();
    toast.success(t(editingId.value ? "categories.updated" : "categories.created", { name: response.category.name })); closeModal(true);
  } catch (error) { await errors.applyApiError(error, formElement.value); toast.error(error.message); }
  finally { saving.value = false; }
}
async function destroyCategory(category) {
  if (!(await confirmToast(t("categories.confirm_delete", { name: category.name }), { confirmLabel: t("common.delete") }))) return;
  deletingIds.value = new Set(deletingIds.value).add(category.id);
  try { await apiFetch(`/api/v1/admin/categories/${category.id}`, { method: "DELETE" }); removeItem(category.id); toast.success(t("categories.deleted", { name: category.name })); }
  catch (error) { toast.error(error.message); }
  finally { const next = new Set(deletingIds.value); next.delete(category.id); deletingIds.value = next; }
}
</script>

<template>
  <AdminLayout><div class="mx-auto max-w-[1536px]">
    <div class="mb-6 flex items-start justify-between gap-4"><div><h1 class="text-2xl font-semibold text-gray-900 dark:text-white">{{ t('categories.title') }}</h1><p class="mt-1 text-sm text-gray-500">{{ t('categories.subtitle') }}</p></div>
      <AsyncButton v-if="can('categories.create')" :loading="false" class="rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-600" @click="openCreate"><Plus :size="17" />{{ t('categories.add') }}</AsyncButton>
    </div>
    <DataTable :items="items" :columns="columns" :loading="loading" :empty-text="t('categories.empty')" server-mode :total="pagination.total" @request="load">
      <template #cell-name="{ item }"><span class="font-medium text-gray-900 dark:text-white">{{ item.name }}</span></template>
      <template #cell-description="{ item }"><p :title="item.description || ''" class="max-w-sm line-clamp-2 text-sm text-gray-500">{{ item.description || '—' }}</p></template>
      <template #cell-active="{ item }"><span :class="item.active ? 'bg-brand-50 text-brand-600' : 'bg-gray-100 text-gray-500'" class="rounded-full px-2.5 py-1 text-xs font-medium">{{ t(item.active ? 'common.active' : 'common.inactive') }}</span></template>
      <template #cell-action="{ item }"><div v-if="canAny(['categories.update','categories.delete'])" class="flex gap-2"><TableActionButton v-if="can('categories.update')" action="edit" :label="t('common.edit')" :accessible-label="t('categories.edit_item', { name: item.name })" @click="openEdit(item)" /><TableActionButton v-if="can('categories.delete')" action="delete" :label="t('common.delete')" :accessible-label="t('categories.delete_item', { name: item.name })" :disabled="item.products_count > 0" :loading="deletingIds.has(item.id)" @click="destroyCategory(item)" /></div><span v-else class="text-xs text-gray-400">{{ t('common.view_only') }}</span></template>
    </DataTable>
  </div>
  <AppModal :open="modalOpen" :title="t(editingId ? 'categories.edit_title' : 'categories.create_title')" :loading="modalLoading" :close-disabled="saving" size="lg" @close="closeModal">
    <form ref="formElement" id="category-form" class="space-y-5" novalidate @submit.prevent="submit"><FormField :label="t('categories.name')" :error="errors.errorFor('name')"><TextInput v-model="form.name" name="name" required :disabled="saving" @input="errors.clearError('name')" /></FormField><FormField :label="t('categories.description')" :error="errors.errorFor('description')"><TextareaInput v-model="form.description" name="description" rows="4" :disabled="saving" @input="errors.clearError('description')" /></FormField><ToggleInput v-model="form.active" :label="t('common.active')" :hint="t('categories.active_hint')" :disabled="saving" /></form>
    <template #footer><button type="button" class="rounded-lg border border-gray-200 px-4 py-2.5 text-sm font-semibold" :disabled="saving" @click="closeModal">{{ t('common.cancel') }}</button><AsyncButton form="category-form" type="submit" :loading="saving" :disabled="editingId && !changed" :loading-text="t('common.saving')" class="rounded-lg bg-brand-500 px-5 py-2.5 text-sm font-semibold text-white"><Save :size="16" />{{ t('common.save') }}</AsyncButton></template>
  </AppModal></AdminLayout>
</template>
