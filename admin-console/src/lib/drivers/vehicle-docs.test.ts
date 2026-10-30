import { describe, expect, it } from "vitest";
import { documentExpiry, latestDocuments, toVehicleCard } from "./vehicle-docs";

const v = {
  plate_number: "ABJ-312KL",
  make_model: "Bajaj RE",
  color: "Green",
  seat_capacity: 3,
  mode_code: "keke",
  verification_status: "verified",
};

describe("toVehicleCard", () => {
  it("unwraps object or array joins", () => {
    expect(toVehicleCard({ since: "s", vehicles: v })?.plate_number).toBe(
      "ABJ-312KL",
    );
    expect(toVehicleCard({ since: "s", vehicles: [v] })?.since).toBe("s");
  });
  it("returns null when RLS hides the vehicle", () => {
    expect(toVehicleCard({ since: "s", vehicles: null })).toBeNull();
    expect(toVehicleCard(null)).toBeNull();
  });
});

describe("latestDocuments", () => {
  it("keeps the newest submission per type", () => {
    const d = (id: string, type: string, at: string) => ({
      id,
      document_type: type,
      status: "pending",
      submitted_at: at,
      expires_at: null,
      rejection_reason: null,
    });
    const out = latestDocuments([
      d("a", "licence", "2026-01-01"),
      d("b", "licence", "2026-03-01"),
      d("c", "nin", "2026-02-01"),
    ]);
    expect(out.map((x) => x.id)).toEqual(["b", "c"]);
  });
});

describe("documentExpiry", () => {
  const now = new Date("2026-10-30T00:00:00Z");
  it("flags expired and soon", () => {
    expect(documentExpiry("2026-10-01T00:00:00Z", now)).toBe("expired");
    expect(documentExpiry("2026-11-10T00:00:00Z", now)).toBe("soon");
    expect(documentExpiry("2027-06-01T00:00:00Z", now)).toBeNull();
    expect(documentExpiry(null, now)).toBeNull();
  });
});
it("labels NIN", async () => {
  const { documentLabel } = await import("./vehicle-docs");
  expect(documentLabel("nin")).toBe("NIN");
  expect(documentLabel("road_worthiness")).toBe("Road worthiness");
});
