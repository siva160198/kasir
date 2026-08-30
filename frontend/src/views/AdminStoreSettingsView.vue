<script setup>
import { onMounted, reactive, ref } from "vue";
import { Save } from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import AsyncButton from "../components/AsyncButton.vue";
import FormField from "../components/FormField.vue";
import SelectInput from "../components/SelectInput.vue";
import TextareaInput from "../components/TextareaInput.vue";
import TextInput from "../components/TextInput.vue";
import ToggleInput from "../components/ToggleInput.vue";
import { apiFetch } from "../services/api";
import { toast } from "../services/toast";
import { t } from "../services/i18n";
const loading = ref(true),
  saving = ref(false),
  logo = ref(null);
const form = reactive({
  store_name: "",
  address: "",
  phone: "",
  email: "",
  tax_id: "",
  currency: "IDR",
  tax_rate: 0,
  prices_include_tax: true,
  rounding_unit: 1,
  receipt_width: 58,
  receipt_header: "",
  receipt_footer: "Terima kasih",
  show_cashier: true,
  show_sku: false,
  show_tax: true,
  printer_name: "",
  printer_copies: 1,
  logo_url: null,
});
async function load() {
  loading.value = true;
  try {
    Object.assign(
      form,
      (await apiFetch("/api/v1/admin/store_setting")).store_setting,
    );
  } finally {
    loading.value = false;
  }
}
async function submit() {
  saving.value = true;
  try {
    const data = new FormData();
    Object.entries(form).forEach(([key, value]) => {
      if (key !== "logo_url" && value != null) data.append(key, value);
    });
    if (logo.value) data.append("logo", logo.value);
    const r = await apiFetch("/api/v1/admin/store_setting", {
      method: "PATCH",
      body: data,
    });
    Object.assign(form, r.store_setting);
    logo.value = null;
    toast.success(t("store.saved"));
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
onMounted(load);
</script>
<template>
  <AdminLayout
    ><div class="mx-auto max-w-6xl">
      <div>
        <h1 class="text-2xl font-semibold dark:text-white">
          {{ t("store.title") }}
        </h1>
        <p class="text-sm text-gray-500">{{ t("store.subtitle") }}</p>
      </div>
      <div v-if="loading" class="py-20 text-center">
        {{ t("common.loading_data") }}
      </div>
      <form
        v-else
        class="mt-6 grid gap-6 lg:grid-cols-[1fr_320px]"
        @submit.prevent="submit"
      >
        <div class="space-y-5">
          <section
            class="grid gap-4 rounded-2xl border bg-white p-5 dark:bg-gray-900 sm:grid-cols-2"
          >
            <h2 class="sm:col-span-2 font-semibold">
              {{ t("store.profile") }}
            </h2>
            <FormField :label="t('store.name')"
              ><TextInput v-model="form.store_name" required /></FormField
            ><FormField :label="t('store.logo')"
              ><input
                type="file"
                accept="image/png,image/jpeg,image/webp"
                @change="logo = $event.target.files[0]" /></FormField
            ><FormField :label="t('supplier.phone')"
              ><TextInput v-model="form.phone" /></FormField
            ><FormField :label="t('common.email')"
              ><TextInput v-model="form.email" type="email" /></FormField
            ><FormField :label="t('store.tax_id')"
              ><TextInput v-model="form.tax_id" /></FormField
            ><FormField :label="t('supplier.address')" class="sm:col-span-2"
              ><TextareaInput v-model="form.address" rows="2"
            /></FormField>
          </section>
          <section
            class="grid gap-4 rounded-2xl border bg-white p-5 dark:bg-gray-900 sm:grid-cols-2"
          >
            <h2 class="sm:col-span-2 font-semibold">
              {{ t("store.transaction") }}
            </h2>
            <FormField :label="t('store.tax_rate')"
              ><TextInput
                v-model.number="form.tax_rate"
                type="number"
                min="0"
                max="100"
                step="0.01" /></FormField
            ><FormField :label="t('store.rounding')"
              ><SelectInput v-model.number="form.rounding_unit"
                ><option v-for="v in [1, 100, 500, 1000]" :key="v" :value="v">
                  Rp{{ v }}
                </option></SelectInput
              ></FormField
            ><ToggleInput
              v-model="form.prices_include_tax"
              :label="t('store.include_tax')"
            />
          </section>
          <section
            class="grid gap-4 rounded-2xl border bg-white p-5 dark:bg-gray-900 sm:grid-cols-2"
          >
            <h2 class="sm:col-span-2 font-semibold">
              {{ t("store.receipt") }}
            </h2>
            <FormField :label="t('store.width')"
              ><SelectInput v-model.number="form.receipt_width"
                ><option :value="58">58 mm</option>
                <option :value="80">80 mm</option></SelectInput
              ></FormField
            ><FormField :label="t('store.printer')"
              ><TextInput v-model="form.printer_name" /></FormField
            ><FormField :label="t('store.header')"
              ><TextInput v-model="form.receipt_header" /></FormField
            ><FormField :label="t('store.footer')"
              ><TextInput v-model="form.receipt_footer" /></FormField
            ><ToggleInput
              v-model="form.show_cashier"
              :label="t('store.show_cashier')"
            /><ToggleInput
              v-model="form.show_sku"
              :label="t('store.show_sku')"
            /><ToggleInput
              v-model="form.show_tax"
              :label="t('store.show_tax')"
            />
          </section>
          <AsyncButton
            type="submit"
            :loading="saving"
            class="rounded-lg bg-brand-500 px-5 py-2.5 text-white"
            ><Save :size="17" />{{ t("common.save") }}</AsyncButton
          >
        </div>
        <aside
          class="h-fit rounded-2xl border bg-gray-100 p-4 lg:sticky lg:top-24"
        >
          <h2 class="mb-3 font-semibold">{{ t("store.preview") }}</h2>
          <article
            :style="{ width: `${form.receipt_width}mm` }"
            class="mx-auto max-w-full bg-white p-3 font-mono text-xs text-black shadow"
          >
            <img
              v-if="form.logo_url"
              :src="form.logo_url"
              class="mx-auto mb-2 max-h-14"
            />
            <h3 class="text-center text-lg font-bold">
              {{ form.store_name || "KASIR" }}
            </h3>
            <p class="text-center">
              {{ form.receipt_header }}<br />{{ form.address }}<br />{{
                form.phone
              }}
            </p>
            <hr class="my-2" />
            <div class="flex justify-between">
              <span>{{ t("receipt.sample_product") }} × 2</span><span>Rp20.000</span>
            </div>
            <hr class="my-2" />
            <div v-if="form.show_tax" class="flex justify-between">
              <span>{{ t("receipt.tax") }} {{ form.tax_rate }}%</span><span>Rp0</span>
            </div>
            <div class="flex justify-between font-bold">
              <span>{{ t("receipt.total") }}</span><span>Rp20.000</span>
            </div>
            <p v-if="form.show_cashier">{{ t("receipt.cashier") }}: admin</p>
            <p class="mt-3 text-center">{{ form.receipt_footer }}</p>
          </article>
        </aside>
      </form>
    </div></AdminLayout
  >
</template>
