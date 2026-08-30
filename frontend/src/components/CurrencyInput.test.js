import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import CurrencyInput from "./CurrencyInput.vue";

describe("CurrencyInput", () => {
  it("formats thousands while keeping an integer model value", async () => {
    const wrapper = mount(CurrencyInput, { props: { modelValue: 15000 } });
    expect(wrapper.get("input").element.value).toBe("15.000");
    await wrapper.get("input").setValue("Rp 1.250.000");
    expect(wrapper.emitted("update:modelValue").at(-1)).toEqual([1250000]);
  });
});
