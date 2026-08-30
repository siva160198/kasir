<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from "vue";
import {
  ArrowLeft,
  Banknote,
  CreditCard,
  Landmark,
  Minus,
  Plus,
  Printer,
  QrCode,
  ShoppingCart,
  Trash2,
} from "@lucide/vue";
import AppModal from "../components/AppModal.vue";
import AsyncButton from "../components/AsyncButton.vue";
import CurrencyInput from "../components/CurrencyInput.vue";
import LanguageSwitcher from "../components/LanguageSwitcher.vue";
import SelectInput from "../components/SelectInput.vue";
import TextInput from "../components/TextInput.vue";
import { apiFetch } from "../services/api";
import { toast } from "../services/toast";
import { t } from "../services/i18n";
const products = ref([]),
  cart = ref([]),
  query = ref(""),
  category = ref(""),
  page = ref(1),
  tab = ref("products"),
  payOpen = ref(false),
  saving = ref(false),
  receipt = ref(null),
  store = ref({
    store_name: "KASIR",
    tax_rate: 0,
    prices_include_tax: true,
    rounding_unit: 1,
    receipt_width: 58,
    receipt_footer: "Terima kasih",
    show_cashier: true,
    show_sku: false,
    show_tax: true,
  }),
  paper = ref("58");
const pay = reactive({ method: "cash", received: 0, reference: "" }),
  perPage = 8;
const paymentMethods = computed(() => [
  { value: "cash", label: t("payment.cash"), icon: Banknote },
  { value: "qris", label: "QRIS", icon: QrCode },
  { value: "transfer", label: t("payment.transfer"), icon: Landmark },
  { value: "debit_card", label: t("payment.debit_card"), icon: CreditCard },
]);
const money = (v) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(v || 0);
const categories = computed(() => [
  ...new Set(products.value.map((p) => p.category_name)),
]);
const filtered = computed(() => {
  const q = query.value.toLowerCase();
  return products.value.filter(
    (p) =>
      (!category.value || p.category_name === category.value) &&
      (!q ||
        [p.name, p.sku, p.barcode].some((v) => v?.toLowerCase().includes(q))),
  );
});
const pages = computed(() =>
    Math.max(1, Math.ceil(filtered.value.length / perPage)),
  ),
  visible = computed(() =>
    filtered.value.slice((page.value - 1) * perPage, page.value * perPage),
  ),
  subtotal = computed(() =>
    cart.value.reduce((n, i) => n + i.selling_price * i.quantity, 0),
  ),
  tax = computed(() =>
    store.value.prices_include_tax
      ? Math.round(
          subtotal.value -
            subtotal.value / (1 + Number(store.value.tax_rate || 0) / 100),
        )
      : Math.round((subtotal.value * Number(store.value.tax_rate || 0)) / 100),
  ),
  total = computed(() => {
    const before = store.value.prices_include_tax
        ? subtotal.value
        : subtotal.value + tax.value,
      unit = Number(store.value.rounding_unit || 1);
    return unit === 1 ? before : Math.round(before / unit) * unit;
  }),
  change = computed(() =>
    pay.method === "cash" ? Math.max(0, pay.received - total.value) : 0,
  );
async function load() {
  const response = await apiFetch("/api/v1/admin/sales/catalog");
  products.value = response.products;
  if (response.store_setting) {
    store.value = response.store_setting;
    paper.value = String(response.store_setting.receipt_width || 58);
  }
  page.value = 1;
}
function add(p) {
  const i = cart.value.find((x) => x.id === p.id);
  if (i) {
    if (i.quantity < p.current_stock) i.quantity++;
  } else cart.value.push({ ...p, quantity: 1 });
}
function qty(i, d) {
  i.quantity += d;
  if (i.quantity < 1) cart.value = cart.value.filter((x) => x.id !== i.id);
}
function searchKey(e) {
  if (e.key !== "Enter") return;
  const p = products.value.find(
    (x) =>
      x.barcode === query.value ||
      x.sku.toLowerCase() === query.value.toLowerCase(),
  );
  if (p) {
    add(p);
    query.value = "";
  }
}
function openPay() {
  if (!cart.value.length) return;
  Object.assign(pay, { method: "cash", received: total.value, reference: "" });
  payOpen.value = true;
}
async function checkout() {
  saving.value = true;
  const sold = cart.value.map((i) => ({ ...i }));
  try {
    const r = await apiFetch("/api/v1/admin/sales", {
      method: "POST",
      body: JSON.stringify({
        client_token: crypto.randomUUID(),
        payment_method: pay.method,
        received_amount: pay.received,
        reference_number: pay.reference,
        items: sold.map((i) => ({ product_id: i.id, quantity: i.quantity })),
      }),
    });
    receipt.value = { ...r.sale, items: sold };
    cart.value = [];
    payOpen.value = false;
    toast.success(t("pos.success", { number: r.sale.sale_number }));
    await load();
  } catch (e) {
    toast.error(e.message);
  } finally {
    saving.value = false;
  }
}
function keys(e) {
  if (e.key === "/" && !payOpen.value) {
    e.preventDefault();
    document.querySelector("[data-pos-search]")?.focus();
  }
  if (e.key === "F2") {
    e.preventDefault();
    openPay();
  }
}
function printReceipt() {
  window.print();
}
onMounted(() => {
  load();
  window.addEventListener("keydown", keys);
});
onBeforeUnmount(() => window.removeEventListener("keydown", keys));
</script>
<template>
  <div
    class="flex h-screen min-h-0 flex-col overflow-hidden bg-gray-50 dark:bg-gray-950"
  >
    <header
      class="flex h-16 shrink-0 items-center justify-between border-b bg-white px-4 dark:bg-gray-900"
    >
      <div class="flex items-center gap-3">
        <RouterLink to="/admin" class="rounded-lg border p-2"
          ><ArrowLeft :size="19"
        /></RouterLink>
        <div>
          <strong class="block dark:text-white">{{ t("pos.title") }}</strong
          ><small class="text-gray-500"
            >/ {{ t("pos.search") }} · F2 {{ t("pos.pay") }}</small
          >
        </div>
      </div>
      <LanguageSwitcher />
    </header>
    <div class="flex shrink-0 gap-2 border-b p-2 lg:hidden">
      <button
        v-for="x in ['products', 'cart']"
        :key="x"
        :class="tab === x ? 'bg-brand-500 text-white' : 'bg-gray-100'"
        class="flex-1 rounded-lg py-2"
        @click="tab = x"
      >
        {{ t(x === "products" ? "nav.products" : "pos.cart") }}
      </button>
    </div>
    <main class="grid min-h-0 flex-1 lg:grid-cols-[minmax(0,1fr)_400px]">
      <section
        :class="tab === 'products' ? 'flex' : 'hidden lg:flex'"
        class="min-h-0 flex-col p-4"
      >
        <div class="grid shrink-0 gap-3 sm:grid-cols-[1fr_220px]">
          <TextInput
            v-model="query"
            data-pos-search
            :placeholder="t('pos.search')"
            @keydown="searchKey"
            @input="page = 1"
          /><SelectInput v-model="category" @change="page = 1"
            ><option value="">{{ t("products.category") }}</option>
            <option v-for="c in categories" :key="c">
              {{ c }}
            </option></SelectInput
          >
        </div>
        <div
          class="grid min-h-0 flex-1 grid-cols-2 grid-rows-4 gap-3 py-4 md:grid-cols-4 md:grid-rows-2"
        >
          <button
            v-for="p in visible"
            :key="p.id"
            class="min-h-0 rounded-xl border bg-white p-3 text-left hover:border-brand-500 dark:bg-gray-900"
            @click="add(p)"
          >
            <strong class="line-clamp-2">{{ p.name }}</strong
            ><small class="block text-gray-500"
              >{{ p.sku }} ·
              {{ t("pos.stock", { count: p.current_stock }) }}</small
            ><b class="mt-2 block text-brand-600">{{
              money(p.selling_price)
            }}</b>
          </button>
        </div>
        <div class="flex shrink-0 justify-center gap-3">
          <button
            class="rounded border px-4 py-2"
            :disabled="page <= 1"
            @click="page--"
          >
            ‹</button
          ><span>{{ page }} / {{ pages }}</span
          ><button
            class="rounded border px-4 py-2"
            :disabled="page >= pages"
            @click="page++"
          >
            ›
          </button>
        </div>
      </section>
      <aside
        :class="tab === 'cart' ? 'flex' : 'hidden lg:flex'"
        class="min-h-0 flex-col border-l bg-white dark:bg-gray-900"
      >
        <h2 class="shrink-0 border-b p-4 font-semibold">
          <ShoppingCart class="mr-2 inline" :size="19" />{{ t("pos.cart") }}
        </h2>
        <div class="min-h-0 flex-1 overflow-y-auto p-4">
          <p v-if="!cart.length" class="pt-16 text-center text-gray-500">
            {{ t("pos.empty_cart") }}
          </p>
          <div v-for="i in cart" :key="i.id" class="mb-3 rounded-xl border p-3">
            <div class="flex justify-between">
              <strong>{{ i.name }}</strong
              ><button @click="qty(i, -i.quantity)">
                <Trash2 :size="17" class="text-error-500" />
              </button>
            </div>
            <div class="mt-3 flex justify-between">
              <span>{{ money(i.selling_price * i.quantity) }}</span>
              <div class="flex gap-2">
                <button @click="qty(i, -1)"><Minus :size="16" /></button
                ><b>{{ i.quantity }}</b
                ><button
                  :disabled="i.quantity >= i.current_stock"
                  @click="qty(i, 1)"
                >
                  <Plus :size="16" />
                </button>
              </div>
            </div>
          </div>
        </div>
        <div class="shrink-0 border-t p-4">
          <div class="flex justify-between text-xl font-bold">
            <span>{{ t("pos.total") }}</span
            ><span>{{ money(total) }}</span>
          </div>
          <AsyncButton
            class="mt-4 w-full rounded-lg bg-brand-500 py-3 text-white"
            :disabled="!cart.length"
            @click="openPay"
            >{{ t("pos.pay") }} · F2</AsyncButton
          >
        </div>
      </aside>
    </main>
    <AppModal
      :open="payOpen"
      :title="t('pos.checkout')"
      :close-disabled="saving"
      @close="payOpen = false"
      ><div class="space-y-5">
        <div class="flex justify-between text-xl font-bold">
          <span>{{ t("pos.total") }}</span
          ><span>{{ money(total) }}</span>
        </div>
        <div class="grid grid-cols-2 gap-3" role="radiogroup">
          <button
            v-for="method in paymentMethods"
            :key="method.value"
            type="button"
            role="radio"
            :aria-checked="pay.method === method.value"
            :class="
              pay.method === method.value
                ? 'border-brand-500 bg-brand-50 text-brand-700 ring-2 ring-brand-500/20 dark:bg-brand-500/10 dark:text-brand-300'
                : 'border-gray-200 bg-white text-gray-700 hover:border-brand-300 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200'
            "
            class="flex min-h-20 items-center gap-3 rounded-xl border p-3 text-left transition"
            @click="pay.method = method.value"
          >
            <span
              :class="
                pay.method === method.value
                  ? 'bg-brand-500 text-white'
                  : 'bg-gray-100 text-gray-500 dark:bg-gray-800'
              "
              class="grid size-10 shrink-0 place-items-center rounded-lg"
            >
              <component :is="method.icon" :size="21" />
            </span>
            <span class="font-semibold">{{ method.label }}</span>
          </button>
        </div>
        <CurrencyInput
          v-if="pay.method === 'cash'"
          v-model="pay.received"
        /><TextInput
          v-else
          v-model="pay.reference"
          :placeholder="t('pos.reference')"
        />
        <p v-if="pay.method === 'cash'">
          {{ t("pos.change") }}: <b>{{ money(change) }}</b>
        </p>
      </div>
      <template #footer
        ><button @click="payOpen = false">{{ t("common.cancel") }}</button
        ><AsyncButton
          :loading="saving"
          :disabled="pay.method === 'cash' && pay.received < total"
          class="rounded-lg bg-brand-500 px-5 py-2.5 text-white"
          @click="checkout"
          >{{ t("pos.pay") }}</AsyncButton
        ></template
      ></AppModal
    ><AppModal
      :open="Boolean(receipt)"
      :title="receipt ? t('pos.success', { number: receipt.sale_number }) : ''"
      size="lg"
      @close="receipt = null"
      ><div v-if="receipt">
        <div class="mb-4 flex gap-2 print:hidden">
          <button
            v-for="s in ['58', '80']"
            :key="s"
            :class="paper === s ? 'bg-brand-500 text-white' : 'border'"
            class="rounded px-3 py-2"
            @click="paper = s"
          >
            {{ s }} mm
          </button>
        </div>
        <article
          :class="paper === '58' ? 'receipt-58' : 'receipt-80'"
          class="thermal-receipt mx-auto bg-white p-3 font-mono text-xs text-black"
        >
          <h2 class="text-center text-lg font-bold">
            {{ store.store_name || t("receipt.store") }}
          </h2>
          <p v-if="store.receipt_header" class="text-center">
            {{ store.receipt_header }}
          </p>
          <p v-if="store.address" class="text-center">{{ store.address }}</p>
          <p class="text-center">
            {{ receipt.sale_number }}<br />{{
              new Date(receipt.completed_at).toLocaleString()
            }}
          </p>
          <hr class="my-2" />
          <div v-for="i in receipt.items" :key="i.id">
            <div>
              {{ i.name }}<span v-if="store.show_sku"> · {{ i.sku }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ i.quantity }} × {{ money(i.selling_price) }}</span
              ><span>{{ money(i.quantity * i.selling_price) }}</span>
            </div>
          </div>
          <hr class="my-2" />
          <div class="flex justify-between font-bold">
            <span>{{ t("pos.total") }}</span
            ><span>{{ money(receipt.total) }}</span>
          </div>
          <div
            v-if="store.show_tax && receipt.tax_amount"
            class="flex justify-between"
          >
            <span>{{ t("receipt.tax") }}</span><span>{{ money(receipt.tax_amount) }}</span>
          </div>
          <div v-if="store.show_cashier && receipt.user_email">
            Kasir: {{ receipt.user_email }}
          </div>
          <div>{{ receipt.payment_method }}</div>
          <div v-if="receipt.payment_method === 'cash'">
            {{ money(receipt.received_amount) }} /
            {{ money(receipt.change_amount) }}
          </div>
          <p class="mt-4 text-center">
            {{ store.receipt_footer || t("receipt.thanks") }}
          </p>
        </article>
      </div>
      <template #footer
        ><button class="rounded border px-4 py-2" @click="receipt = null">
          {{ t("pos.new_sale") }}</button
        ><AsyncButton
          class="rounded bg-brand-500 px-4 py-2 text-white"
          @click="printReceipt"
          ><Printer :size="16" />{{ t("pos.print") }}</AsyncButton
        ></template
      ></AppModal
    >
  </div>
</template>
<style>
.receipt-58 {
  width: 58mm;
}
.receipt-80 {
  width: 80mm;
}
@media print {
  @page {
    margin: 0;
  }
  body * {
    visibility: hidden !important;
  }
  .thermal-receipt,
  .thermal-receipt * {
    visibility: visible !important;
  }
  .thermal-receipt {
    position: absolute;
    left: 0;
    top: 0;
    margin: 0 !important;
  }
}
</style>
