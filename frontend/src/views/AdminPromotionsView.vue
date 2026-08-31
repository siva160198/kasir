<script setup>
import { computed, reactive, ref } from "vue";
import { Plus, Tag } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import CurrencyInput from "../components/CurrencyInput.vue";
import DataTable from "../components/DataTable.vue";
import FormField from "../components/FormField.vue";
import SelectInput from "../components/SelectInput.vue";
import TableActionButton from "../components/TableActionButton.vue";
import TextInput from "../components/TextInput.vue";
import ToggleInput from "../components/ToggleInput.vue";
import { apiFetch } from "../services/api";
import { useAuth } from "../services/auth";
import { useServerTable } from "../services/serverTable";
import { confirmToast, toast } from "../services/toast";
import { t } from "../services/i18n";
const { can } = useAuth(),
  { items, loading, pagination, load } = useServerTable({
    endpoint: "/api/v1/admin/promotions",
    collectionKey: "promotions",
  });
const open = ref(false),
  modalLoading = ref(false),
  saving = ref(false),
  editing = ref(null);
const now = () =>
  new Date(Date.now() - new Date().getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
const later = () =>
  new Date(Date.now() + 30 * 86400000 - new Date().getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
const form = reactive({
  name: "",
  code: "",
  discount_type: "percentage",
  value: 10,
  minimum_purchase: 0,
  maximum_discount: "",
  starts_at: now(),
  ends_at: later(),
  usage_limit: "",
  active: true,
});
const columns = computed(() => [
  { key: "code", label: t("promotion.code") },
  { key: "name", label: t("promotion.name") },
  { key: "discount_type", label: t("promotion.discount") },
  { key: "minimum_purchase", label: t("promotion.minimum") },
  { key: "usage_count", label: t("promotion.usage") },
  { key: "active", label: t("common.status") },
  { key: "action", label: t("common.action"), sortable: false },
]);
const money = (v) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(v || 0);
const displayDiscount = (p) =>
  p.discount_type === "percentage" ? `${p.value}%` : money(p.value);
const local = (v) => (v ? new Date(v).toISOString().slice(0, 16) : "");
function createPromotion() {
  editing.value = null;
  Object.assign(form, {
    name: "",
    code: "",
    discount_type: "percentage",
    value: 10,
    minimum_purchase: 0,
    maximum_discount: "",
    starts_at: now(),
    ends_at: later(),
    usage_limit: "",
    active: true,
  });
  open.value = true;
}
async function edit(item) {
  editing.value = item.id;
  open.value = true;
  modalLoading.value = true;
  try {
    const r = await apiFetch(`/api/v1/admin/promotions/${item.id}`);
    Object.assign(form, r.promotion, {
      starts_at: local(r.promotion.starts_at),
      ends_at: local(r.promotion.ends_at),
      maximum_discount: r.promotion.maximum_discount ?? "",
      usage_limit: r.promotion.usage_limit ?? "",
    });
  } catch (e) {
    toast.error(e.message);
    open.value = false;
  } finally {
    modalLoading.value = false;
  }
}
async function submit() {
  if (!form.name.trim() || !form.code.trim())
    return toast.error(t("validation.fix_fields"));
  saving.value = true;
  try {
    const payload = {
      ...form,
      maximum_discount: form.maximum_discount || null,
      usage_limit: form.usage_limit || null,
    };
    await apiFetch(
      editing.value
        ? `/api/v1/admin/promotions/${editing.value}`
        : "/api/v1/admin/promotions",
      {
        method: editing.value ? "PATCH" : "POST",
        body: JSON.stringify(payload),
      },
    );
    toast.success(t("promotion.saved"));
    open.value = false;
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
async function remove(item) {
  if (!(await confirmToast(t("promotion.confirm_delete", { code: item.code }))))
    return;
  try {
    await apiFetch(`/api/v1/admin/promotions/${item.id}`, { method: "DELETE" });
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
            {{ t("promotion.title") }}
          </h1>
          <p class="text-sm text-gray-500">{{ t("promotion.subtitle") }}</p>
        </div>
        <AsyncButton
          v-if="can('promotions.create')"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="createPromotion"
          ><Plus :size="17" />{{ t("promotion.add") }}</AsyncButton
        >
      </div>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
        ><template #cell-code="{ item }"
          ><span class="inline-flex items-center gap-1 font-mono font-semibold"
            ><Tag :size="14" />{{ item.code }}</span
          ></template
        ><template #cell-discount_type="{ item }">{{
          displayDiscount(item)
        }}</template
        ><template #cell-minimum_purchase="{ item }">{{
          money(item.minimum_purchase)
        }}</template
        ><template #cell-usage_count="{ item }"
          >{{ item.usage_count }} / {{ item.usage_limit || "∞" }}</template
        ><template #cell-active="{ item }"
          ><span
            class="rounded-full bg-gray-100 px-2 py-1 text-xs dark:bg-gray-800"
            >{{ t(item.active ? "common.active" : "common.inactive") }}</span
          ></template
        ><template #cell-action="{ item }"
          ><div class="flex gap-2">
            <TableActionButton
              v-if="can('promotions.update')"
              action="edit"
              :label="t('common.edit')"
              @click="edit(item)"
            /><TableActionButton
              v-if="can('promotions.delete')"
              action="delete"
              :label="t('common.delete')"
              :disabled="item.usage_count > 0"
              @click="remove(item)"
            /></div></template
      ></DataTable>
      <AppModal
        :open="open"
        :loading="modalLoading"
        :title="t(editing ? 'promotion.edit' : 'promotion.add')"
        size="lg"
        :close-disabled="saving"
        @close="open = false"
        ><form id="promotion-form" class="space-y-4" @submit.prevent="submit">
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('promotion.name')"
              ><TextInput v-model="form.name" required /></FormField
            ><FormField :label="t('promotion.code')"
              ><TextInput v-model="form.code" required
            /></FormField>
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('promotion.type')"
              ><SelectInput v-model="form.discount_type"
                ><option value="percentage">
                  {{ t("promotion.percentage") }}
                </option>
                <option value="fixed">
                  {{ t("promotion.fixed") }}
                </option></SelectInput
              ></FormField
            ><FormField :label="t('promotion.value')"
              ><TextInput
                v-if="form.discount_type === 'percentage'"
                v-model="form.value"
                type="number"
                min="1"
                max="100" /><CurrencyInput v-else v-model="form.value"
            /></FormField>
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('promotion.minimum')"
              ><CurrencyInput v-model="form.minimum_purchase" /></FormField
            ><FormField :label="t('promotion.maximum')"
              ><CurrencyInput v-model="form.maximum_discount"
            /></FormField>
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <FormField :label="t('promotion.starts')"
              ><TextInput
                v-model="form.starts_at"
                type="datetime-local" /></FormField
            ><FormField :label="t('promotion.ends')"
              ><TextInput v-model="form.ends_at" type="datetime-local"
            /></FormField>
          </div>
          <FormField :label="t('promotion.limit')"
            ><TextInput
              v-model="form.usage_limit"
              type="number"
              min="1" /></FormField
          ><ToggleInput v-model="form.active" :label="t('common.active')" />
        </form>
        <template #footer
          ><button @click="open = false">{{ t("common.cancel") }}</button
          ><AsyncButton
            form="promotion-form"
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
