<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from "vue";
import { onBeforeRouteLeave, useRouter } from "vue-router";
import {
  ArrowLeft,
  Banknote,
  CreditCard,
  Landmark,
  Minus,
  Plus,
  Percent,
  Pause,
  Play,
  X,
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
  customers = ref([]),
  promotions = ref([]),
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
const router = useRouter();
const posVerified = ref(false),
  posChallenge = ref(""),
  posOtp = ref(""),
  otpLoading = ref(false),
  shiftChecking = ref(true),
  currentShift = ref(null),
  exitOpen = ref(false),
  customerSearch = ref(""),
  promotionSearch = ref(""),
  customerMenu = ref(false),
  promotionMenu = ref(false);
let allowExit = false;
const heldOpen = ref(false),
  holdNameOpen = ref(false),
  holdName = ref(""),
  discountItem = ref(null),
  splitPayment = ref(false),
  paymentRows = ref([]);
const heldSales = ref(loadHeldSales());
const pay = reactive({
    method: "cash",
    received: 0,
    reference: "",
    customer_id: "",
    promotion_code: "",
  }),
  perPage = 8;
const paymentMethods = computed(() => [
  { value: "cash", label: t("payment.cash"), icon: Banknote },
  { value: "qris", label: "QRIS", icon: QrCode },
  { value: "transfer", label: t("payment.transfer"), icon: Landmark },
  { value: "debit_card", label: t("payment.debit_card"), icon: CreditCard },
]);
const filteredCustomers = computed(() => {
  const query = customerSearch.value.trim().toLowerCase();
  return customers.value
    .filter(
      (customer) =>
        !query ||
        [customer.name, customer.phone, customer.customer_number].some(
          (value) => value?.toLowerCase().includes(query),
        ),
    )
    .slice(0, 6);
});
const filteredPromotions = computed(() => {
  const query = promotionSearch.value.trim().toLowerCase();
  return promotions.value
    .filter(
      (promotion) =>
        !query ||
        [promotion.name, promotion.code].some((value) =>
          value?.toLowerCase().includes(query),
        ),
    )
    .slice(0, 6);
});
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
  itemDiscount = computed(() =>
    cart.value.reduce((sum, item) => sum + Number(item.discount || 0), 0),
  ),
  promotionBase = computed(() => subtotal.value - itemDiscount.value),
  selectedPromotion = computed(() =>
    promotions.value.find((promotion) => promotion.code === pay.promotion_code),
  ),
  promotionDiscount = computed(() => {
    const promotion = selectedPromotion.value;
    if (!promotion || promotionBase.value < promotion.minimum_purchase)
      return 0;
    const amount =
      promotion.discount_type === "percentage"
        ? Math.round((promotionBase.value * promotion.value) / 100)
        : promotion.value;
    return Math.min(
      amount,
      promotion.maximum_discount || amount,
      promotionBase.value,
    );
  }),
  discount = computed(() => itemDiscount.value + promotionDiscount.value),
  discountedSubtotal = computed(() => subtotal.value - discount.value),
  tax = computed(() =>
    store.value.prices_include_tax
      ? Math.round(
          discountedSubtotal.value -
            discountedSubtotal.value /
              (1 + Number(store.value.tax_rate || 0) / 100),
        )
      : Math.round(
          (discountedSubtotal.value * Number(store.value.tax_rate || 0)) / 100,
        ),
  ),
  total = computed(() => {
    const before = store.value.prices_include_tax
        ? discountedSubtotal.value
        : discountedSubtotal.value + tax.value,
      unit = Number(store.value.rounding_unit || 1);
    return unit === 1 ? before : Math.round(before / unit) * unit;
  }),
  change = computed(() =>
    pay.method === "cash" ? Math.max(0, pay.received - total.value) : 0,
  ),
  paymentAllocated = computed(() =>
    paymentRows.value.reduce((sum, row) => sum + Number(row.amount || 0), 0),
  ),
  splitValid = computed(
    () =>
      paymentRows.value.length > 0 &&
      paymentAllocated.value === total.value &&
      paymentRows.value.every(
        (row) =>
          Number(row.amount) > 0 &&
          (row.payment_method !== "cash" ||
            Number(row.received_amount) >= Number(row.amount)),
      ),
  );

function loadHeldSales() {
  try {
    return JSON.parse(localStorage.getItem("kasir-held-sales") || "[]");
  } catch {
    return [];
  }
}
function saveHeldSales() {
  localStorage.setItem("kasir-held-sales", JSON.stringify(heldSales.value));
}
function holdSale() {
  if (!cart.value.length) return;
  holdName.value = `${t("pos.held_sale")} ${heldSales.value.length + 1}`;
  holdNameOpen.value = true;
}
function confirmHold() {
  heldSales.value.push({
    id: crypto.randomUUID(),
    name: holdName.value.trim() || t("pos.held_sale"),
    created_at: new Date().toISOString(),
    cart: cart.value,
    pay: { customer_id: pay.customer_id, promotion_code: pay.promotion_code },
  });
  saveHeldSales();
  cart.value = [];
  Object.assign(pay, { customer_id: "", promotion_code: "" });
  holdNameOpen.value = false;
  toast.success(t("pos.held"));
}
function restoreHeld(entry) {
  cart.value = entry.cart;
  Object.assign(pay, entry.pay || {});
  heldSales.value = heldSales.value.filter((row) => row.id !== entry.id);
  saveHeldSales();
  heldOpen.value = false;
  toast.success(t("pos.restored"));
}
function removeHeld(entry) {
  heldSales.value = heldSales.value.filter((row) => row.id !== entry.id);
  saveHeldSales();
}
function openDiscount(item) {
  discountItem.value = { ...item, discount: Number(item.discount || 0) };
}
function applyDiscount() {
  const item = cart.value.find((row) => row.id === discountItem.value.id);
  if (item)
    item.discount = Math.min(
      Math.max(0, Number(discountItem.value.discount || 0)),
      item.selling_price * item.quantity,
    );
  discountItem.value = null;
}
function setSplit(value) {
  splitPayment.value = value;
  paymentRows.value = value
    ? [
        {
          payment_method: "cash",
          amount: total.value,
          received_amount: total.value,
          reference_number: "",
        },
      ]
    : [];
}
function addPayment() {
  paymentRows.value.push({
    payment_method: "qris",
    amount: Math.max(0, total.value - paymentAllocated.value),
    received_amount: 0,
    reference_number: "",
  });
}
function removePayment(index) {
  paymentRows.value.splice(index, 1);
}
async function requestPosOtp() {
  otpLoading.value = true;
  try {
    const response = await apiFetch("/api/v1/step_up", {
      method: "POST",
      body: JSON.stringify({ purpose: "pos_access" }),
    });
    posChallenge.value = response.challenge_token;
    toast.info(t("auth.otp_sent", { email: response.email_hint }));
  } catch (error) {
    toast.error(error.message);
  } finally {
    otpLoading.value = false;
  }
}
async function initializePos() {
  shiftChecking.value = true;
  try {
    const response = await apiFetch("/api/v1/admin/cashier_shifts/current");
    currentShift.value = response.cashier_shift;
    if (!currentShift.value) return;
    if (currentShift.value.pos_access_verified) {
      posVerified.value = true;
      await load();
    } else {
      await requestPosOtp();
    }
  } catch (error) {
    toast.error(error.message);
  } finally {
    shiftChecking.value = false;
  }
}
async function verifyPosOtp() {
  if (!/^\d{6}$/.test(posOtp.value)) return toast.error(t("validation.otp"));
  otpLoading.value = true;
  try {
    await apiFetch("/api/v1/step_up/verify", {
      method: "POST",
      body: JSON.stringify({
        purpose: "pos_access",
        challenge_token: posChallenge.value,
        code: posOtp.value,
      }),
    });
    posVerified.value = true;
    await load();
    toast.success(t("pos.access_verified"));
  } catch (error) {
    toast.error(error.message);
  } finally {
    otpLoading.value = false;
  }
}
function selectCustomer(customer) {
  pay.customer_id = customer?.id || "";
  customerSearch.value = customer?.name || "";
  customerMenu.value = false;
}
function selectPromotion(promotion) {
  pay.promotion_code = promotion?.code || "";
  promotionSearch.value = promotion
    ? `${promotion.code} · ${promotion.name}`
    : "";
  promotionMenu.value = false;
}
function searchCustomer() {
  pay.customer_id = "";
  customerMenu.value = true;
}
function searchPromotion() {
  pay.promotion_code = "";
  promotionMenu.value = true;
}
function requestExit() {
  exitOpen.value = true;
}
function openShift() {
  allowExit = true;
  router.push("/admin/my-shift");
}
function confirmExit() {
  allowExit = true;
  exitOpen.value = false;
  router.push("/admin");
}
function beforeUnload(event) {
  if (!posVerified.value) return;
  event.preventDefault();
  event.returnValue = "";
}
async function load() {
  const response = await apiFetch("/api/v1/admin/sales/catalog");
  products.value = response.products;
  customers.value = response.customers || [];
  promotions.value = response.promotions || [];
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
  } else cart.value.push({ ...p, quantity: 1, discount: 0 });
}
function qty(i, d) {
  i.quantity += d;
  i.discount = Math.min(
    Number(i.discount || 0),
    i.selling_price * Math.max(i.quantity, 0),
  );
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
  if (!currentShift.value) return;
  Object.assign(pay, {
    method: "cash",
    received: total.value,
    reference: "",
    customer_id: "",
    promotion_code: "",
  });
  setSplit(false);
  customerSearch.value = "";
  promotionSearch.value = "";
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
        customer_id: pay.customer_id || null,
        promotion_code: pay.promotion_code || null,
        items: sold.map((i) => ({
          product_id: i.id,
          quantity: i.quantity,
          discount: Number(i.discount || 0),
        })),
        ...(splitPayment.value ? { payments: paymentRows.value } : {}),
      }),
    });
    receipt.value = { ...r.sale, items: sold };
    cart.value = [];
    Object.assign(pay, { customer_id: "", promotion_code: "" });
    payOpen.value = false;
    toast.success(t("pos.success", { number: r.sale.sale_number }));
    await load();
  } catch (e) {
    if (e.code === "SHIFT_REQUIRED") {
      payOpen.value = false;
      posVerified.value = false;
      currentShift.value = null;
    } else if (e.code === "POS_VERIFICATION_REQUIRED") {
      payOpen.value = false;
      posVerified.value = false;
      await initializePos();
    }
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
  initializePos();
  window.addEventListener("keydown", keys);
  window.addEventListener("beforeunload", beforeUnload);
});
onBeforeUnmount(() => {
  window.removeEventListener("keydown", keys);
  window.removeEventListener("beforeunload", beforeUnload);
});
onBeforeRouteLeave(() => allowExit || window.confirm(t("pos.exit_confirm")));
</script>
<template>
  <div
    class="flex h-screen min-h-0 flex-col overflow-hidden bg-gray-50 dark:bg-gray-950"
  >
    <header
      class="flex h-16 shrink-0 items-center justify-between border-b bg-white px-4 dark:bg-gray-900"
    >
      <div class="flex items-center gap-3">
        <button
          :aria-label="t('pos.exit')"
          class="rounded-lg border p-2"
          @click="requestExit"
        >
          <ArrowLeft :size="19" />
        </button>
        <div>
          <strong class="block dark:text-white">{{ t("pos.title") }}</strong
          ><small class="text-gray-500"
            >/ {{ t("pos.search") }} · F2 {{ t("pos.pay") }}</small
          >
        </div>
      </div>
      <div class="flex items-center gap-2">
        <button
          class="relative rounded-lg border p-2"
          :aria-label="t('pos.held_list')"
          @click="heldOpen = true"
        >
          <Pause :size="19" /><span
            v-if="heldSales.length"
            class="absolute -right-2 -top-2 rounded-full bg-brand-500 px-1.5 text-xs text-white"
            >{{ heldSales.length }}</span
          ></button
        ><LanguageSwitcher />
      </div>
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
              <span
                ><span
                  :class="i.discount ? 'text-gray-400 line-through' : ''"
                  >{{ money(i.selling_price * i.quantity) }}</span
                ><b v-if="i.discount" class="ml-2 text-brand-600">{{
                  money(i.selling_price * i.quantity - i.discount)
                }}</b></span
              >
              <div class="flex gap-2">
                <button
                  :aria-label="t('pos.item_discount')"
                  @click="openDiscount(i)"
                >
                  <Percent :size="16" />
                </button>
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
          <div class="mt-4 grid grid-cols-[auto_1fr] gap-2">
            <AsyncButton
              class="rounded-lg border px-4 py-3"
              :disabled="!cart.length"
              @click="holdSale"
              ><Pause :size="17" />{{ t("pos.hold") }}</AsyncButton
            ><AsyncButton
              class="rounded-lg bg-brand-500 py-3 text-white"
              :disabled="!cart.length"
              @click="openPay"
              >{{ t("pos.pay") }} · F2</AsyncButton
            >
          </div>
        </div>
      </aside>
    </main>
    <AppModal
      :open="payOpen"
      :title="t('pos.checkout')"
      :close-disabled="saving"
      @close="payOpen = false"
      ><div class="space-y-5">
        <div class="grid gap-3 sm:grid-cols-2">
          <div class="relative">
            <TextInput
              v-model="customerSearch"
              :placeholder="t('pos.search_customer')"
              @focus="customerMenu = true"
              @input="searchCustomer"
            />
            <div
              v-if="customerMenu"
              class="absolute z-20 mt-1 max-h-48 w-full overflow-y-auto rounded-lg border bg-white p-1 shadow-lg dark:bg-gray-900"
            >
              <button
                class="w-full rounded-md px-3 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-800"
                @click="selectCustomer(null)"
              >
                {{ t("pos.general_customer") }}</button
              ><button
                v-for="customer in filteredCustomers"
                :key="customer.id"
                class="w-full rounded-md px-3 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-800"
                @click="selectCustomer(customer)"
              >
                <b>{{ customer.name }}</b
                ><small class="block text-gray-500"
                  >{{ customer.phone || customer.customer_number
                  }}{{
                    customer.member
                      ? ` · ${customer.points} ${t("customer.points")}`
                      : ""
                  }}</small
                >
              </button>
              <p
                v-if="!filteredCustomers.length"
                class="p-3 text-sm text-gray-500"
              >
                {{ t("pos.no_customer_result") }}
              </p>
            </div>
          </div>
          <div class="relative">
            <TextInput
              v-model="promotionSearch"
              :placeholder="t('pos.search_promotion')"
              @focus="promotionMenu = true"
              @input="searchPromotion"
            />
            <div
              v-if="promotionMenu"
              class="absolute z-20 mt-1 max-h-48 w-full overflow-y-auto rounded-lg border bg-white p-1 shadow-lg dark:bg-gray-900"
            >
              <button
                class="w-full rounded-md px-3 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-800"
                @click="selectPromotion(null)"
              >
                {{ t("pos.no_promotion") }}</button
              ><button
                v-for="promotion in filteredPromotions"
                :key="promotion.id"
                :disabled="promotionBase < promotion.minimum_purchase"
                class="w-full rounded-md px-3 py-2 text-left text-sm hover:bg-gray-50 disabled:opacity-40 dark:hover:bg-gray-800"
                @click="selectPromotion(promotion)"
              >
                <b>{{ promotion.code }} · {{ promotion.name }}</b
                ><small class="block text-gray-500"
                  >{{ t("promotion.minimum") }}
                  {{ money(promotion.minimum_purchase) }}</small
                >
              </button>
              <p
                v-if="!filteredPromotions.length"
                class="p-3 text-sm text-gray-500"
              >
                {{ t("pos.no_promotion_result") }}
              </p>
            </div>
          </div>
        </div>
        <div
          v-if="discount"
          class="flex justify-between rounded-lg bg-brand-50 p-3 text-sm text-brand-700 dark:bg-brand-500/10 dark:text-brand-300"
        >
          <span>{{ t("pos.discount") }} · {{ pay.promotion_code }}</span
          ><b>-{{ money(discount) }}</b>
        </div>
        <div class="flex justify-between text-xl font-bold">
          <span>{{ t("pos.total") }}</span
          ><span>{{ money(total) }}</span>
        </div>
        <div class="flex rounded-lg bg-gray-100 p-1 dark:bg-gray-800">
          <button
            v-for="option in [false, true]"
            :key="String(option)"
            class="flex-1 rounded-md px-3 py-2 text-sm"
            :class="
              splitPayment === option
                ? 'bg-white shadow-sm dark:bg-gray-900'
                : ''
            "
            @click="setSplit(option)"
          >
            {{ t(option ? "pos.split_payment" : "pos.single_payment") }}
          </button>
        </div>
        <template v-if="!splitPayment"
          ><div class="grid grid-cols-2 gap-3" role="radiogroup">
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
        </template>
        <div v-else class="space-y-3">
          <div
            v-for="(row, index) in paymentRows"
            :key="index"
            class="grid gap-2 rounded-xl border p-3 sm:grid-cols-[150px_1fr_1fr_auto]"
          >
            <SelectInput v-model="row.payment_method"
              ><option
                v-for="method in paymentMethods"
                :key="method.value"
                :value="method.value"
              >
                {{ method.label }}
              </option></SelectInput
            ><CurrencyInput v-model="row.amount" /><CurrencyInput
              v-if="row.payment_method === 'cash'"
              v-model="row.received_amount"
            /><TextInput
              v-else
              v-model="row.reference_number"
              :placeholder="t('pos.reference')"
            /><button
              :aria-label="t('common.delete')"
              @click="removePayment(index)"
            >
              <X :size="17" />
            </button>
          </div>
          <button
            class="rounded-lg border px-3 py-2 text-sm"
            @click="addPayment"
          >
            <Plus :size="16" class="inline" />{{ t("pos.add_payment") }}
          </button>
          <div
            class="flex justify-between text-sm"
            :class="
              paymentAllocated === total ? 'text-brand-600' : 'text-error-600'
            "
          >
            <span>{{ t("pos.allocated") }}</span
            ><b>{{ money(paymentAllocated) }} / {{ money(total) }}</b>
          </div>
        </div>
      </div>
      <template #footer
        ><button @click="payOpen = false">{{ t("common.cancel") }}</button
        ><AsyncButton
          :loading="saving"
          :disabled="
            splitPayment
              ? !splitValid
              : pay.method === 'cash' && pay.received < total
          "
          class="rounded-lg bg-brand-500 px-5 py-2.5 text-white"
          @click="checkout"
          >{{ t("pos.pay") }}</AsyncButton
        ></template
      ></AppModal
    ><AppModal
      :open="holdNameOpen"
      :title="t('pos.hold')"
      @close="holdNameOpen = false"
      ><TextInput
        v-model="holdName"
        :placeholder="t('pos.hold_name')"
      /><template #footer
        ><button @click="holdNameOpen = false">{{ t("common.cancel") }}</button
        ><AsyncButton
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="confirmHold"
          >{{ t("pos.hold") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
      :open="!shiftChecking && Boolean(currentShift) && !posVerified"
      :title="t('pos.otp_title')"
      :close-disabled="true"
      size="md"
      ><div class="space-y-4">
        <p class="text-sm text-gray-600 dark:text-gray-300">
          {{ t("pos.otp_hint") }}
        </p>
        <TextInput
          v-model="posOtp"
          inputmode="numeric"
          maxlength="6"
          autocomplete="one-time-code"
          :placeholder="t('auth.otp')"
          @keydown.enter="verifyPosOtp"
        /><button
          class="text-sm font-semibold text-brand-600"
          :disabled="otpLoading"
          @click="requestPosOtp"
        >
          {{ t("auth.resend") }}
        </button>
      </div>
      <template #footer
        ><AsyncButton
          :loading="otpLoading"
          class="w-full rounded-lg bg-brand-500 px-4 py-2.5 text-white"
          @click="verifyPosOtp"
          >{{ t("common.verify") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
      :open="!shiftChecking && !currentShift"
      :title="t('pos.shift_required_title')"
      :close-disabled="true"
      size="md"
    >
      <div class="space-y-4 text-center">
        <div
          class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-warning-50 text-warning-600 dark:bg-warning-500/10"
        >
          <Banknote :size="27" />
        </div>
        <p class="text-sm leading-6 text-gray-600 dark:text-gray-300">
          {{ t("pos.shift_required_hint") }}
        </p>
      </div>
      <template #footer>
        <AsyncButton
          class="w-full rounded-lg bg-brand-500 px-4 py-2.5 text-white"
          @click="openShift"
        >
          {{ t("shift.open") }}
        </AsyncButton>
      </template>
    </AppModal>
    <AppModal
      :open="exitOpen"
      :title="t('pos.exit_title')"
      size="sm"
      @close="exitOpen = false"
      ><p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t("pos.exit_confirm") }}
      </p>
      <template #footer
        ><button class="rounded-lg border px-4 py-2" @click="exitOpen = false">
          {{ t("common.no") }}</button
        ><AsyncButton
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="confirmExit"
          >{{ t("common.yes") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
      :open="heldOpen"
      :title="t('pos.held_list')"
      @close="heldOpen = false"
      ><p v-if="!heldSales.length" class="text-sm text-gray-500">
        {{ t("pos.no_held") }}
      </p>
      <div v-else class="space-y-2">
        <div
          v-for="entry in heldSales"
          :key="entry.id"
          class="flex items-center justify-between rounded-xl border p-3"
        >
          <div>
            <b>{{ entry.name }}</b
            ><small class="block text-gray-500"
              >{{ new Date(entry.created_at).toLocaleString() }} ·
              {{ entry.cart.length }} {{ t("sales.items") }}</small
            >
          </div>
          <div class="flex gap-2">
            <button
              class="rounded-lg border p-2"
              :aria-label="t('pos.restore')"
              @click="restoreHeld(entry)"
            >
              <Play :size="17" /></button
            ><button
              class="rounded-lg border border-error-200 p-2 text-error-600"
              :aria-label="t('common.delete')"
              @click="removeHeld(entry)"
            >
              <Trash2 :size="17" />
            </button>
          </div>
        </div></div
    ></AppModal>
    <AppModal
      :open="Boolean(discountItem)"
      :title="t('pos.item_discount')"
      @close="discountItem = null"
      ><div v-if="discountItem" class="space-y-3">
        <p class="font-semibold">{{ discountItem.name }}</p>
        <p class="text-sm text-gray-500">
          {{ t("pos.item_gross") }}:
          {{ money(discountItem.selling_price * discountItem.quantity) }}
        </p>
        <CurrencyInput v-model="discountItem.discount" />
      </div>
      <template #footer
        ><button @click="discountItem = null">{{ t("common.cancel") }}</button
        ><AsyncButton
          class="rounded-lg bg-brand-500 px-4 py-2 text-white"
          @click="applyDiscount"
          >{{ t("common.save") }}</AsyncButton
        ></template
      ></AppModal
    >
    <AppModal
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
            <span>{{ t("receipt.tax") }}</span
            ><span>{{ money(receipt.tax_amount) }}</span>
          </div>
          <div v-if="receipt.discount">
            <span
              >{{ t("pos.discount") }} {{ receipt.promotion_code || "" }}</span
            ><span>-{{ money(receipt.discount) }}</span>
          </div>
          <div v-if="receipt.customer_name">
            {{ t("customer.title") }}: {{ receipt.customer_name }}
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
