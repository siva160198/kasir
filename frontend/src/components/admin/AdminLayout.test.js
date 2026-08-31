import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import { beforeEach, describe, expect, it, vi } from "vitest";
import AdminLayout from "./AdminLayout.vue";
import { resetAuthState, useAuth } from "../../services/auth";

vi.mock("vue-router", () => ({
  useRoute: () => ({ path: "/admin" }),
  useRouter: () => ({ push: vi.fn() }),
}));

beforeEach(() => {
  resetAuthState();
  useAuth().setUser({
    email_address: "admin@example.com",
    permissions: ["dashboard.view", "profile.view"],
  });
});

function mountLayout() {
  return mount(AdminLayout, {
    global: {
      stubs: {
        RouterLink: { template: "<a><slot /></a>" },
      },
    },
  });
}

describe("AdminLayout", () => {
  it("collapses the desktop sidebar to an icon rail and persists the choice", async () => {
    const wrapper = mountLayout();

    await wrapper.get('[aria-label="Kecilkan sidebar"]').trigger("click");

    expect(wrapper.get("aside").classes()).toContain("lg:w-[90px]");
    expect(wrapper.get('[aria-label="Lebarkan sidebar"]').exists()).toBe(true);
    expect(localStorage.getItem("kasir-sidebar")).toBe("closed");
  });

  it("restores the collapsed sidebar preference", async () => {
    localStorage.setItem("kasir-sidebar", "closed");
    const wrapper = mountLayout();
    await nextTick();

    expect(wrapper.get("aside").classes()).toContain("lg:w-[90px]");
  });

  it("keeps operational and security tools out of the sidebar", () => {
    useAuth().setUser({
      email_address: "admin@example.com",
      permissions: [
        "dashboard.view",
        "profile.view",
        "audit_logs.view",
        "jobs.view",
        "api_docs.view",
        "security_approvals.view",
      ],
    });

    const sidebarText = mountLayout().get("aside").text();

    expect(sidebarText).not.toContain("Log audit");
    expect(sidebarText).not.toContain("Antrean job");
    expect(sidebarText).not.toContain("Dokumentasi API");
    expect(sidebarText).not.toContain("Persetujuan keamanan");
  });

  it("orders navigation by the store workflow", () => {
    useAuth().setUser({
      email_address: "admin@example.com",
      permissions: [
        "dashboard.view",
        "users.view",
        "categories.view",
        "products.view",
        "inventory.view",
        "cashier_shifts.view_own",
        "sales.create",
        "sales.view_own",
        "store_settings.manage",
        "expenses.view",
        "stock_counts.view",
        "customers.view",
        "promotions.view",
        "purchases.view",
        "suppliers.view",
        "reports.view",
      ],
    });

    const sidebarText = mountLayout().get("aside").text();

    expect(sidebarText.indexOf("Dasbor")).toBeLessThan(
      sidebarText.indexOf("Shift Kasir"),
    );
    expect(sidebarText.indexOf("Shift Kasir")).toBeLessThan(
      sidebarText.indexOf("Transaksi"),
    );
    expect(sidebarText.indexOf("Transaksi")).toBeLessThan(
      sidebarText.indexOf("Produk"),
    );
    expect(sidebarText.indexOf("Produk")).toBeLessThan(
      sidebarText.indexOf("Stok"),
    );
    expect(sidebarText.indexOf("Stok")).toBeLessThan(
      sidebarText.indexOf("Stock Opname"),
    );
    expect(sidebarText.indexOf("Stock Opname")).toBeLessThan(
      sidebarText.indexOf("Pembelian"),
    );
    expect(sidebarText.indexOf("Pembelian")).toBeLessThan(
      sidebarText.indexOf("Supplier"),
    );
    expect(sidebarText.indexOf("Supplier")).toBeLessThan(
      sidebarText.indexOf("Pelanggan"),
    );
    expect(sidebarText.indexOf("Pelanggan")).toBeLessThan(
      sidebarText.indexOf("Promosi"),
    );
    expect(sidebarText.indexOf("Promosi")).toBeLessThan(
      sidebarText.indexOf("Pengeluaran"),
    );
    expect(sidebarText.indexOf("Pengeluaran")).toBeLessThan(
      sidebarText.indexOf("Laporan"),
    );
    expect(sidebarText.indexOf("Laporan")).toBeLessThan(
      sidebarText.indexOf("Manajemen Pengguna"),
    );
    expect(sidebarText.indexOf("Manajemen Pengguna")).toBeLessThan(
      sidebarText.indexOf("Pengaturan Toko"),
    );
  });

  it("shows the profile link above sign out in the account dropdown", async () => {
    const wrapper = mountLayout();
    await wrapper.get('[aria-label="Menu akun"]').trigger("click");

    const dropdownText = wrapper.text();
    expect(dropdownText.indexOf("Profil")).toBeGreaterThan(-1);
    expect(dropdownText.indexOf("Profil")).toBeLessThan(
      dropdownText.indexOf("Keluar"),
    );

    document.body.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await nextTick();
    expect(wrapper.text()).not.toContain("Keluar");
  });

  it("closes the notification dropdown when clicking outside", async () => {
    const wrapper = mountLayout();
    await wrapper.get('[aria-label="Notifikasi"]').trigger("click");
    expect(wrapper.text()).toContain("Belum ada notifikasi baru.");

    document.body.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await nextTick();
    expect(wrapper.text()).not.toContain("Belum ada notifikasi baru.");
  });

  it("shows only a visually truncated name before the account menu opens", () => {
    useAuth().setUser({
      first_name: "Alexander",
      last_name: "Hamilton",
      email_address: "alex@example.com",
      permissions: ["dashboard.view", "profile.view"],
    });
    const wrapper = mountLayout();
    const label = wrapper.get('[aria-label="Menu akun"] strong');

    expect(label.text()).toBe("Alexander Hamilton");
    expect(label.classes()).toContain("max-w-[8ch]");
    expect(wrapper.get('[aria-label="Menu akun"]').text()).not.toContain(
      "alex@example.com",
    );
  });
});
