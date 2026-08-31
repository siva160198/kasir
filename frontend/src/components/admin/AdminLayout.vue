<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import {
  Bell,
  ChevronDown,
  Compass,
  LayoutDashboard,
  LogOut,
  Menu,
  Moon,
  PanelLeftClose,
  PanelLeftOpen,
  Package,
  Tags,
  Boxes,
  History,
  SlidersHorizontal,
  Clock3,
  ShoppingCart,
  ReceiptText,
  BarChart3,
  ClipboardList,
  Truck,
  Settings,
  WalletCards,
  ClipboardCheck,
  ContactRound,
  BadgePercent,
  Search,
  ShieldCheck,
  Sun,
  Users,
  UserRound,
  X,
} from "@lucide/vue";
import AsyncButton from "../AsyncButton.vue";
import LanguageSwitcher from "../LanguageSwitcher.vue";
import { useClickOutside } from "../../composables/useClickOutside";
import { t } from "../../services/i18n";
import { toast } from "../../services/toast";
import { useAuth } from "../../services/auth";
import { apiFetch } from "../../services/api";

const route = useRoute();
const router = useRouter();
const { user, permissions, logout, logoutLoading } = useAuth();
const profileInitial = computed(
  () =>
    user.value?.first_name?.charAt(0).toUpperCase() ||
    user.value?.email_address?.charAt(0).toUpperCase() ||
    "U",
);
const accountName = computed(
  () =>
    [user.value?.first_name, user.value?.last_name].filter(Boolean).join(" ") ||
    user.value?.email_address?.split("@")[0] ||
    t("profile.menu"),
);
const sidebarOpen = ref(false);
const desktopSidebarOpen = ref(true);
const profileOpen = ref(false);
const profileMenu = ref(null);
const notificationOpen = ref(false);
const stockAlerts = ref({ count: 0, alerts: [] });
const notificationMenu = ref(null);
const dark = ref(false);
const userManagementOpen = ref(
  route.path.startsWith("/admin/users") ||
    route.path.startsWith("/admin/roles"),
);
const catalogOpen = ref(
  route.path.startsWith("/admin/categories") ||
    route.path.startsWith("/admin/products"),
);
const stockOpen = ref(
  route.path.startsWith("/admin/inventory") ||
    route.path.startsWith("/admin/stock-"),
);
const shiftsOpen = ref(route.path.includes("shift"));
const salesOpen = ref(
  route.path === "/admin/pos" || route.path === "/admin/sales",
);

useClickOutside(profileMenu, () => {
  profileOpen.value = false;
});
useClickOutside(notificationMenu, () => {
  notificationOpen.value = false;
});

const navigation = computed(() => [
  {
    label: t("nav.dashboard"),
    icon: LayoutDashboard,
    to: "/admin",
    permission: "dashboard.view",
  },
  {
    key: "shifts",
    label: t("nav.shifts"),
    icon: Clock3,
    children: [
      {
        label: t("nav.my_shift"),
        icon: Clock3,
        to: "/admin/my-shift",
        permission: "cashier_shifts.view_own",
      },
      {
        label: t("nav.shift_history"),
        icon: History,
        to: "/admin/shift-history",
        permission: "cashier_shifts.view_own",
      },
    ],
  },
  {
    key: "sales",
    label: t("nav.transactions"),
    icon: ShoppingCart,
    children: [
      {
        label: t("nav.pos"),
        icon: ShoppingCart,
        to: "/admin/pos",
        permission: "sales.create",
      },
      {
        label: t("nav.sales_history"),
        icon: ReceiptText,
        to: "/admin/sales",
        permission: "sales.view_own",
      },
    ],
  },
  {
    key: "catalog",
    label: t("nav.catalog"),
    icon: Package,
    children: [
      {
        label: t("nav.categories"),
        icon: Tags,
        to: "/admin/categories",
        permission: "categories.view",
      },
      {
        label: t("nav.products"),
        icon: Package,
        to: "/admin/products",
        permission: "products.view",
      },
    ],
  },
  {
    key: "stock",
    label: t("nav.stock"),
    icon: Boxes,
    children: [
      {
        label: t("nav.inventory"),
        icon: Boxes,
        to: "/admin/inventory",
        permission: "inventory.view",
      },
      {
        label: t("nav.stock_counts"),
        icon: ClipboardCheck,
        to: "/admin/stock-counts",
        permission: "stock_counts.view",
      },
      {
        label: t("nav.stock_adjustments"),
        icon: SlidersHorizontal,
        to: "/admin/stock-adjustments",
        permission: "stock_adjustments.create",
      },
      {
        label: t("nav.stock_movements"),
        icon: History,
        to: "/admin/stock-movements",
        permission: "stock_movements.view",
      },
    ],
  },
  {
    label: t("nav.purchases"),
    icon: ClipboardList,
    to: "/admin/purchases",
    permission: "purchases.view",
  },
  {
    label: t("nav.suppliers"),
    icon: Truck,
    to: "/admin/suppliers",
    permission: "suppliers.view",
  },
  {
    label: t("nav.customers"),
    icon: ContactRound,
    to: "/admin/customers",
    permission: "customers.view",
  },
  {
    label: t("nav.promotions"),
    icon: BadgePercent,
    to: "/admin/promotions",
    permission: "promotions.view",
  },
  {
    label: t("nav.expenses"),
    icon: WalletCards,
    to: "/admin/expenses",
    permission: "expenses.view",
  },
  {
    label: t("nav.reports"),
    icon: BarChart3,
    to: "/admin/reports",
    permission: "reports.view",
  },
  {
    key: "users",
    label: t("nav.user_management"),
    icon: Users,
    children: [
      {
        label: t("nav.users"),
        icon: Users,
        to: "/admin/users",
        permission: "users.view",
      },
      {
        label: t("nav.roles"),
        icon: ShieldCheck,
        to: "/admin/roles",
        permission: "roles.view",
      },
    ],
  },
  {
    label: t("nav.store_settings"),
    icon: Settings,
    to: "/admin/store-settings",
    permission: "store_settings.manage",
  },
]);

const visibleNavigation = computed(() =>
  navigation.value.flatMap((item) => {
    if (item.permission && !permissions.value.includes(item.permission))
      return [];
    if (!item.children) return [item];
    const children = item.children.filter((child) =>
      permissions.value.includes(child.permission),
    );
    return children.length ? [{ ...item, children }] : [];
  }),
);

onMounted(() => {
  dark.value = localStorage.getItem("kasir-theme") === "dark";
  desktopSidebarOpen.value = localStorage.getItem("kasir-sidebar") !== "closed";
  document.documentElement.classList.toggle("dark", dark.value);
  if (permissions.value.includes("inventory.view"))
    apiFetch("/api/v1/admin/inventory/alerts")
      .then((value) => {
        stockAlerts.value = value;
      })
      .catch(() => {});
});

function toggleTheme() {
  dark.value = !dark.value;
  document.documentElement.classList.toggle("dark", dark.value);
  localStorage.setItem("kasir-theme", dark.value ? "dark" : "light");
}

function toggleDesktopSidebar() {
  desktopSidebarOpen.value = !desktopSidebarOpen.value;
  localStorage.setItem(
    "kasir-sidebar",
    desktopSidebarOpen.value ? "open" : "closed",
  );
}

function groupOpen(item) {
  if (item.key === "catalog") return catalogOpen.value;
  if (item.key === "stock") return stockOpen.value;
  if (item.key === "shifts") return shiftsOpen.value;
  if (item.key === "sales") return salesOpen.value;
  return userManagementOpen.value;
}

function toggleGroup(item) {
  const wasCollapsed = !desktopSidebarOpen.value;
  if (wasCollapsed) desktopSidebarOpen.value = true;
  const target =
    item.key === "catalog"
      ? catalogOpen
      : item.key === "stock"
        ? stockOpen
        : item.key === "shifts"
          ? shiftsOpen
          : item.key === "sales"
            ? salesOpen
            : userManagementOpen;
  target.value = wasCollapsed ? true : !target.value;
  localStorage.setItem("kasir-sidebar", "open");
}

async function signOut() {
  try {
    await logout();
    await router.push("/login");
  } catch (requestError) {
    toast.error(requestError.message);
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 font-outfit dark:bg-gray-900">
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-40 bg-gray-900/50 lg:hidden"
      @click="sidebarOpen = false"
    ></div>

    <aside
      :class="[
        sidebarOpen ? 'translate-x-0' : '-translate-x-full',
        desktopSidebarOpen ? 'lg:w-[290px] lg:px-5' : 'lg:w-[90px] lg:px-3',
      ]"
      class="fixed inset-y-0 left-0 z-50 flex w-[290px] flex-col border-r border-gray-200 bg-white px-5 transition-[width,transform,padding] duration-300 dark:border-gray-800 dark:bg-gray-900 lg:translate-x-0"
    >
      <div class="flex h-20 items-center justify-between px-2">
        <RouterLink
          to="/admin"
          :class="desktopSidebarOpen ? '' : 'lg:mx-auto'"
          class="flex items-center gap-3"
        >
          <span
            class="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-500 text-white"
            ><Compass :size="22"
          /></span>
          <span :class="desktopSidebarOpen ? '' : 'lg:hidden'"
            ><strong class="block text-xl text-gray-900 dark:text-white"
              >Kasir</strong
            ><small class="text-gray-400">{{ t("admin.console") }}</small></span
          >
        </RouterLink>
        <button class="text-gray-500 lg:hidden" @click="sidebarOpen = false">
          <X :size="22" />
        </button>
      </div>

      <nav class="mt-6 flex-1 overflow-y-auto">
        <p
          :class="desktopSidebarOpen ? '' : 'lg:hidden'"
          class="mb-4 px-3 text-xs font-medium uppercase tracking-wider text-gray-400"
        >
          {{ t("admin.menu") }}
        </p>
        <ul class="space-y-2">
          <li v-for="item in visibleNavigation" :key="item.label">
            <RouterLink
              v-if="item.to"
              :to="item.to"
              :title="desktopSidebarOpen ? undefined : item.label"
              :class="[
                route.path === item.to
                  ? 'bg-brand-50 text-brand-600 dark:bg-brand-500/10 dark:text-brand-400'
                  : 'text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-white/5',
                desktopSidebarOpen ? '' : 'lg:justify-center',
              ]"
              class="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium"
              @click="sidebarOpen = false"
            >
              <component :is="item.icon" :size="20" /><span
                :class="desktopSidebarOpen ? '' : 'lg:hidden'"
                >{{ item.label }}</span
              >
            </RouterLink>
            <template v-else-if="item.children">
              <button
                :title="desktopSidebarOpen ? undefined : item.label"
                :class="[
                  item.children.some((child) => route.path === child.to)
                    ? 'bg-brand-50 text-brand-600 dark:bg-brand-500/10 dark:text-brand-400'
                    : 'text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-white/5',
                  desktopSidebarOpen ? '' : 'lg:justify-center',
                ]"
                class="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium"
                :aria-expanded="groupOpen(item)"
                @click="toggleGroup(item)"
              >
                <component :is="item.icon" :size="20" /><span
                  :class="desktopSidebarOpen ? '' : 'lg:hidden'"
                  >{{ item.label }}</span
                ><ChevronDown
                  :class="[
                    groupOpen(item) ? 'rotate-180' : '',
                    desktopSidebarOpen ? '' : 'lg:hidden',
                  ]"
                  :size="16"
                  class="ml-auto transition-transform"
                />
              </button>
              <ul
                v-show="groupOpen(item)"
                :class="desktopSidebarOpen ? '' : 'lg:hidden'"
                class="ml-5 mt-2 space-y-1 border-l border-gray-200 pl-4 dark:border-gray-700"
              >
                <li v-for="child in item.children" :key="child.to">
                  <RouterLink
                    :to="child.to"
                    :class="
                      route.path === child.to
                        ? 'bg-brand-50 text-brand-600 dark:bg-brand-500/10 dark:text-brand-400'
                        : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/5'
                    "
                    class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium"
                    @click="sidebarOpen = false"
                  >
                    <component :is="child.icon" :size="17" />{{ child.label }}
                  </RouterLink>
                </li>
              </ul>
            </template>
          </li>
        </ul>
      </nav>

      <div
        :class="desktopSidebarOpen ? 'p-4' : 'lg:flex lg:justify-center lg:p-3'"
        class="mb-6 rounded-2xl bg-gray-50 dark:bg-white/5"
      >
        <div :class="desktopSidebarOpen ? '' : 'lg:hidden'">
          <p class="text-sm font-semibold text-gray-900 dark:text-white">
            Kasir API
          </p>
          <div class="mt-2 flex items-center gap-2 text-xs text-gray-500">
            <span class="h-2 w-2 rounded-full bg-brand-500"></span
            >{{ t("admin.operational") }}
          </div>
        </div>
        <span
          v-if="!desktopSidebarOpen"
          class="hidden h-3 w-3 rounded-full bg-brand-500 ring-4 ring-brand-50 dark:ring-brand-500/10 lg:block"
          :title="t('admin.operational')"
        ></span>
      </div>
    </aside>

    <div
      :class="desktopSidebarOpen ? 'lg:pl-[290px]' : 'lg:pl-[90px]'"
      class="transition-[padding] duration-300"
    >
      <header
        class="sticky top-0 z-30 flex h-20 items-center justify-between border-b border-gray-200 bg-white px-4 dark:border-gray-800 dark:bg-gray-900 sm:px-6"
      >
        <div class="flex items-center gap-3">
          <button
            :aria-label="t('admin.open_menu')"
            class="flex h-10 w-10 items-center justify-center rounded-lg border border-gray-200 text-gray-500 dark:border-gray-800 lg:hidden"
            @click="sidebarOpen = true"
          >
            <Menu :size="20" />
          </button>
          <button
            :aria-label="
              t(
                desktopSidebarOpen
                  ? 'admin.collapse_sidebar'
                  : 'admin.expand_sidebar',
              )
            "
            :title="
              t(
                desktopSidebarOpen
                  ? 'admin.collapse_sidebar'
                  : 'admin.expand_sidebar',
              )
            "
            class="hidden h-10 w-10 items-center justify-center rounded-lg border border-gray-200 text-gray-500 hover:bg-gray-100 dark:border-gray-800 dark:hover:bg-gray-800 lg:flex"
            @click="toggleDesktopSidebar"
          >
            <PanelLeftClose v-if="desktopSidebarOpen" :size="20" />
            <PanelLeftOpen v-else :size="20" />
          </button>
          <div class="relative hidden md:block">
            <Search
              :size="18"
              class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
            />
            <input
              class="w-72 rounded-lg border border-gray-200 bg-transparent py-2.5 pl-10 pr-4 text-sm outline-none focus:border-brand-400 dark:border-gray-800 dark:text-white"
              :placeholder="t('admin.search')"
            />
          </div>
        </div>
        <div class="flex items-center gap-3">
          <button
            class="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 text-gray-500 hover:bg-gray-100 dark:border-gray-800 dark:hover:bg-gray-800"
            @click="toggleTheme"
          >
            <Sun v-if="dark" :size="19" /><Moon v-else :size="19" />
          </button>
          <div ref="notificationMenu" class="relative">
            <button
              :aria-label="t('admin.notifications')"
              :aria-expanded="notificationOpen"
              class="relative flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 text-gray-500 hover:bg-gray-100 dark:border-gray-800 dark:hover:bg-gray-800"
              @click="notificationOpen = !notificationOpen"
            >
              <Bell :size="19" /><span
                v-if="stockAlerts.count"
                class="absolute -right-1 -top-1 min-w-5 rounded-full bg-error-600 px-1 text-center text-[10px] font-bold leading-5 text-white"
                >{{ stockAlerts.count > 99 ? "99+" : stockAlerts.count }}</span
              >
            </button>
            <div
              v-if="notificationOpen"
              class="absolute right-0 z-50 mt-3 w-[min(20rem,calc(100vw-2rem))] rounded-xl border border-gray-200 bg-white p-4 shadow-theme-lg dark:border-gray-800 dark:bg-gray-900"
            >
              <div class="border-b border-gray-100 pb-3 dark:border-gray-800">
                <h2 class="text-sm font-semibold text-gray-900 dark:text-white">
                  {{ t("admin.notifications") }}
                </h2>
              </div>
              <div v-if="stockAlerts.alerts.length" class="divide-y">
                <RouterLink
                  v-for="alert in stockAlerts.alerts"
                  :key="alert.id"
                  to="/admin/inventory"
                  class="block py-3 text-sm"
                  @click="notificationOpen = false"
                  ><strong>{{ alert.name }}</strong>
                  <p class="text-xs text-gray-500">
                    {{
                      t("stock.alert_line", {
                        stock: alert.current_stock,
                        count: alert.recommended_quantity,
                      })
                    }}
                  </p></RouterLink
                ><RouterLink
                  to="/admin/inventory"
                  class="mt-2 block text-center text-sm font-semibold text-brand-600"
                  @click="notificationOpen = false"
                  >{{ t("stock.view_recommendations") }}</RouterLink
                >
              </div>
              <div v-else class="py-8 text-center">
                <Bell :size="24" class="mx-auto text-gray-400" />
                <p class="mt-3 text-sm text-gray-500">
                  {{ t("admin.no_notifications") }}
                </p>
              </div>
            </div>
          </div>
          <LanguageSwitcher />
          <div ref="profileMenu" class="relative">
            <button
              :aria-label="t('profile.account_menu')"
              class="flex items-center gap-3"
              @click="profileOpen = !profileOpen"
            >
              <span
                class="flex h-10 w-10 items-center justify-center overflow-hidden rounded-full bg-brand-100 font-semibold text-brand-600 dark:bg-brand-500/15 dark:text-brand-400"
                ><img
                  v-if="user?.avatar_url"
                  :src="user.avatar_url"
                  :alt="t('profile.avatar_alt')"
                  class="h-full w-full object-cover"
                /><span v-else>{{ profileInitial }}</span></span
              >
              <span class="hidden text-left md:block"
                ><strong
                  class="block max-w-[8ch] truncate text-sm text-gray-700 dark:text-gray-200"
                  :title="accountName"
                  >{{ accountName }}</strong
                ></span
              >
              <ChevronDown :size="16" class="hidden text-gray-400 md:block" />
            </button>
            <div
              v-if="profileOpen"
              class="absolute right-0 mt-3 w-64 rounded-xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-900"
            >
              <div
                class="border-b border-gray-100 px-2 pb-3 dark:border-gray-800"
              >
                <p class="text-sm font-medium dark:text-white">
                  <span>{{ accountName }}</span>
                </p>
                <p class="mt-1 truncate text-xs text-gray-500">
                  {{ user?.email_address }}
                </p>
                <p class="mt-1 text-xs capitalize text-gray-400">
                  {{ user?.role }}
                </p>
              </div>
              <RouterLink
                v-if="permissions.includes('profile.view')"
                to="/profile"
                class="mt-2 flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800"
                @click="profileOpen = false"
                ><UserRound :size="18" />{{ t("profile.menu") }}</RouterLink
              >
              <AsyncButton
                :loading="logoutLoading"
                :loading-text="t('admin.signing_out')"
                class="mt-2 w-full justify-start rounded-lg px-2 py-2 text-sm text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800"
                @click="signOut"
                ><LogOut :size="18" />{{ t("admin.sign_out") }}</AsyncButton
              >
            </div>
          </div>
        </div>
      </header>
      <main class="p-4 sm:p-6"><slot /></main>
    </div>
  </div>
</template>
