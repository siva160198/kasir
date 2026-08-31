<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from "vue";
import { Image, Save, Trash2, UploadCloud } from "@lucide/vue";
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
  logo = ref(null),
  logoInput = ref(null),
  logoPreviewUrl = ref(""),
  draggingLogo = ref(false);
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
  remove_logo: false,
});
const displayedLogo = computed(() => logoPreviewUrl.value || form.logo_url);
function clearObjectUrl() {
  if (logoPreviewUrl.value) URL.revokeObjectURL(logoPreviewUrl.value);
  logoPreviewUrl.value = "";
}
function selectLogo(file) {
  if (!file) return;
  if (!["image/png", "image/jpeg", "image/webp"].includes(file.type)) {
    toast.error(t("store.logo_type_error"));
    return;
  }
  if (file.size > 1024 * 1024) {
    toast.error(t("store.logo_size_error"));
    return;
  }
  clearObjectUrl();
  logo.value = file;
  logoPreviewUrl.value = URL.createObjectURL(file);
  form.remove_logo = false;
}
function handleLogoInput(event) {
  selectLogo(event.target.files?.[0]);
  event.target.value = "";
}
function handleLogoDrop(event) {
  draggingLogo.value = false;
  selectLogo(event.dataTransfer?.files?.[0]);
}
function removeLogo() {
  clearObjectUrl();
  logo.value = null;
  form.remove_logo = Boolean(form.logo_url);
  form.logo_url = null;
}
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
    clearObjectUrl();
    form.remove_logo = false;
    toast.success(t("store.saved"));
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
onMounted(load);
onBeforeUnmount(clearObjectUrl);
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
            ><FormField :label="t('store.logo')" class="sm:col-span-2">
              <div
                class="flex flex-col gap-4 rounded-xl border border-dashed p-4 transition sm:flex-row sm:items-center"
                :class="
                  draggingLogo
                    ? 'border-brand-500 bg-brand-50 dark:bg-brand-500/10'
                    : 'border-gray-300 bg-gray-50/70 dark:border-gray-700 dark:bg-gray-800/40'
                "
                @dragenter.prevent="draggingLogo = true"
                @dragover.prevent="draggingLogo = true"
                @dragleave.prevent="draggingLogo = false"
                @drop.prevent="handleLogoDrop"
              >
                <div
                  class="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-xl border bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900"
                >
                  <img
                    v-if="displayedLogo"
                    :src="displayedLogo"
                    :alt="t('store.logo_preview')"
                    class="h-full w-full object-contain p-2"
                  />
                  <Image v-else :size="30" class="text-gray-400" />
                </div>
                <div class="min-w-0 flex-1">
                  <p
                    class="truncate text-sm font-semibold text-gray-800 dark:text-white"
                  >
                    {{
                      logo?.name ||
                      (displayedLogo
                        ? t("store.current_logo")
                        : t("store.no_logo"))
                    }}
                  </p>
                  <p class="mt-1 text-xs leading-5 text-gray-500">
                    {{ t("store.logo_hint") }}
                    <span
                      v-if="logo"
                      class="font-medium text-gray-700 dark:text-gray-300"
                    >
                      · {{ (logo.size / 1024).toFixed(1) }} KB
                    </span>
                  </p>
                  <div class="mt-3 flex flex-wrap gap-2">
                    <button
                      type="button"
                      class="inline-flex items-center gap-2 rounded-lg bg-brand-500 px-3 py-2 text-sm font-semibold text-white hover:bg-brand-600"
                      @click="logoInput?.click()"
                    >
                      <UploadCloud :size="16" />
                      {{
                        t(
                          displayedLogo
                            ? "store.change_logo"
                            : "store.choose_logo",
                        )
                      }}
                    </button>
                    <button
                      v-if="displayedLogo"
                      type="button"
                      class="inline-flex items-center gap-2 rounded-lg border border-error-200 px-3 py-2 text-sm font-semibold text-error-600 hover:bg-error-50 dark:border-error-500/30 dark:hover:bg-error-500/10"
                      @click="removeLogo"
                    >
                      <Trash2 :size="16" />{{ t("store.remove_logo") }}
                    </button>
                  </div>
                </div>
                <input
                  ref="logoInput"
                  type="file"
                  class="sr-only"
                  accept="image/png,image/jpeg,image/webp"
                  @change="handleLogoInput"
                />
              </div> </FormField
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
              v-if="displayedLogo"
              :src="displayedLogo"
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
              <span>{{ t("receipt.sample_product") }} × 2</span
              ><span>Rp20.000</span>
            </div>
            <hr class="my-2" />
            <div v-if="form.show_tax" class="flex justify-between">
              <span>{{ t("receipt.tax") }} {{ form.tax_rate }}%</span
              ><span>Rp0</span>
            </div>
            <div class="flex justify-between font-bold">
              <span>{{ t("receipt.total") }}</span
              ><span>Rp20.000</span>
            </div>
            <p v-if="form.show_cashier">{{ t("receipt.cashier") }}: admin</p>
            <p class="mt-3 text-center">{{ form.receipt_footer }}</p>
          </article>
        </aside>
      </form>
    </div></AdminLayout
  >
</template>
