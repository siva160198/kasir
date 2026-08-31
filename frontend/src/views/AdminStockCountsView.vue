<script setup>
import { computed, reactive, ref } from "vue";
import { ClipboardCheck, Plus } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import DataTable from "../components/DataTable.vue";
import FormField from "../components/FormField.vue";
import TableActionButton from "../components/TableActionButton.vue";
import TextareaInput from "../components/TextareaInput.vue";
import TextInput from "../components/TextInput.vue";
import { apiFetch } from "../services/api";
import { useAuth } from "../services/auth";
import { useServerTable } from "../services/serverTable";
import { confirmToast, toast } from "../services/toast";
import { t } from "../services/i18n";

const { can } = useAuth();
const { items, loading, pagination, load } = useServerTable({
  endpoint: "/api/v1/admin/stock_counts",
  collectionKey: "stock_counts",
});
const createOpen = ref(false),
  creating = ref(false),
  detailOpen = ref(false),
  detailLoading = ref(false),
  finalizing = ref(false),
  savingItem = ref(null),
  detail = ref(null);
const createForm = reactive({
  counted_on: new Date().toISOString().slice(0, 10),
  notes: "",
});
const columns = computed(() => [
  { key: "counted_on", label: t("stock_count.date") },
  { key: "count_number", label: t("stock_count.number"), sortable: false },
  { key: "status", label: t("common.status") },
  { key: "counted_count", label: t("stock_count.progress"), sortable: false },
  {
    key: "total_difference",
    label: t("stock_count.difference"),
    sortable: false,
  },
  { key: "action", label: t("common.action"), sortable: false },
]);
async function createCount() {
  creating.value = true;
  try {
    const r = await apiFetch("/api/v1/admin/stock_counts", {
      method: "POST",
      body: JSON.stringify(createForm),
    });
    createOpen.value = false;
    toast.success(
      t("stock_count.created", { number: r.stock_count.count_number }),
    );
    await load();
    await openDetail(r.stock_count);
  } catch (e) {
    toast.error(e.message);
  } finally {
    creating.value = false;
  }
}
async function openDetail(item) {
  detailOpen.value = true;
  detailLoading.value = true;
  try {
    const r = await apiFetch(`/api/v1/admin/stock_counts/${item.id}`);
    detail.value = r.stock_count;
  } catch (e) {
    toast.error(e.message);
    detailOpen.value = false;
  } finally {
    detailLoading.value = false;
  }
}
async function savePhysical(item) {
  savingItem.value = item.id;
  try {
    const r = await apiFetch(
      `/api/v1/admin/stock_counts/${detail.value.id}/items/${item.id}`,
      {
        method: "PATCH",
        body: JSON.stringify({ counted_stock: Number(item.counted_stock) }),
      },
    );
    Object.assign(item, r.item);
  } catch (e) {
    toast.error(e.message);
  } finally {
    savingItem.value = null;
  }
}
async function finalize() {
  if (!(await confirmToast(t("stock_count.confirm_finalize")))) return;
  finalizing.value = true;
  try {
    const r = await apiFetch(
      `/api/v1/admin/stock_counts/${detail.value.id}/finalize`,
      { method: "PATCH", body: "{}" },
    );
    detail.value = r.stock_count;
    toast.success(t("stock_count.finalized"));
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    finalizing.value = false;
  }
}
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-[1536px] space-y-6">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 class="text-2xl font-semibold dark:text-white">
            {{ t("stock_count.title") }}
          </h1>
          <p class="text-sm text-gray-500">{{ t("stock_count.subtitle") }}</p>
        </div>
        <AsyncButton
          v-if="can('stock_counts.create')"
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="createOpen = true"
          ><Plus :size="17" />{{ t("stock_count.add") }}</AsyncButton
        >
      </div>
      <DataTable
        :items="items"
        :columns="columns"
        :loading="loading"
        server-mode
        :total="pagination.total"
        @request="load"
        ><template #cell-status="{ item }"
          ><span
            class="rounded-full bg-gray-100 px-2 py-1 text-xs dark:bg-gray-800"
            >{{ t(`stock_count.${item.status}`) }}</span
          ></template
        ><template #cell-counted_count="{ item }"
          >{{ item.counted_count }} / {{ item.item_count }}</template
        ><template #cell-total_difference="{ item }"
          ><span :class="item.total_difference !== 0 && 'text-error-600'"
            >{{ item.total_difference > 0 ? "+" : ""
            }}{{ item.total_difference }}</span
          ></template
        ><template #cell-action="{ item }"
          ><TableActionButton
            action="view"
            :label="t('common.view')"
            @click="openDetail(item)" /></template
      ></DataTable>
      <AppModal
        :open="createOpen"
        :title="t('stock_count.add')"
        :close-disabled="creating"
        @close="createOpen = false"
        ><form id="count-form" class="space-y-4" @submit.prevent="createCount">
          <FormField :label="t('stock_count.date')"
            ><TextInput
              v-model="createForm.counted_on"
              type="date"
              required /></FormField
          ><FormField :label="t('stock_count.note')"
            ><TextareaInput v-model="createForm.notes" rows="3"
          /></FormField>
          <p
            class="rounded-lg bg-gray-50 p-3 text-sm text-gray-600 dark:bg-gray-800 dark:text-gray-300"
          >
            {{ t("stock_count.snapshot_hint") }}
          </p>
        </form>
        <template #footer
          ><button @click="createOpen = false">{{ t("common.cancel") }}</button
          ><AsyncButton
            form="count-form"
            type="submit"
            :loading="creating"
            class="rounded-lg bg-brand-500 px-4 py-2 text-white"
            >{{ t("stock_count.create") }}</AsyncButton
          ></template
        ></AppModal
      >
      <AppModal
        :open="detailOpen"
        :loading="detailLoading"
        :title="detail?.count_number || t('stock_count.detail')"
        size="xl"
        :close-disabled="finalizing || Boolean(savingItem)"
        @close="detailOpen = false"
        ><div v-if="detail" class="space-y-4">
          <div class="grid gap-3 sm:grid-cols-3">
            <div
              class="rounded-xl border border-gray-200 p-3 dark:border-gray-800"
            >
              <p class="text-xs text-gray-500">
                {{ t("stock_count.progress") }}
              </p>
              <p class="font-semibold dark:text-white">
                {{ detail.counted_count }} / {{ detail.item_count }}
              </p>
            </div>
            <div
              class="rounded-xl border border-gray-200 p-3 dark:border-gray-800"
            >
              <p class="text-xs text-gray-500">
                {{ t("stock_count.difference") }}
              </p>
              <p class="font-semibold dark:text-white">
                {{ detail.total_difference }}
              </p>
            </div>
            <div
              class="rounded-xl border border-gray-200 p-3 dark:border-gray-800"
            >
              <p class="text-xs text-gray-500">{{ t("common.status") }}</p>
              <p class="font-semibold dark:text-white">
                {{ t(`stock_count.${detail.status}`) }}
              </p>
            </div>
          </div>
          <div class="max-h-[50vh] space-y-2 overflow-y-auto pr-1">
            <div
              v-for="item in detail.items"
              :key="item.id"
              class="grid items-center gap-3 rounded-xl border border-gray-200 p-3 dark:border-gray-800 sm:grid-cols-[1fr_100px_150px_100px]"
            >
              <div>
                <p class="font-medium dark:text-white">
                  {{ item.product_name }}
                </p>
                <p class="text-xs text-gray-500">
                  {{ item.sku }} · {{ item.unit }}
                </p>
              </div>
              <div class="text-sm">
                <span class="text-gray-500">{{ t("stock_count.system") }}</span
                ><br />{{ item.system_stock }}
              </div>
              <TextInput
                v-model="item.counted_stock"
                type="number"
                min="0"
                :disabled="detail.status === 'completed'"
                :aria-label="t('stock_count.physical')"
              /><AsyncButton
                v-if="detail.status === 'draft' && can('stock_counts.update')"
                :loading="savingItem === item.id"
                class="rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-gray-700"
                @click="savePhysical(item)"
                >{{ t("common.save") }}</AsyncButton
              >
              <div v-else class="text-sm">
                {{ item.difference > 0 ? "+" : "" }}{{ item.difference }}
              </div>
            </div>
          </div>
        </div>
        <template #footer
          ><button @click="detailOpen = false">{{ t("common.close") }}</button
          ><AsyncButton
            v-if="detail?.status === 'draft' && can('stock_counts.update')"
            :loading="finalizing"
            class="rounded-lg bg-brand-500 px-4 py-2 text-white"
            @click="finalize"
            ><ClipboardCheck :size="17" />{{
              t("stock_count.finalize")
            }}</AsyncButton
          ></template
        ></AppModal
      >
    </div></AdminLayout
  >
</template>
