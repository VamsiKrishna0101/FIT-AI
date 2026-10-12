# Equipment images

User-supplied WebP assets. These ship in the app and load without a CDN.
All images use `BoxFit.contain`, with width-only decoding to preserve their
original proportions. Do not crop or stretch the machines to fill a card.

The catalog has 21 separate equipment choices, plus No equipment. There are
19 images: leg curl shares the leg extension image, and rear delt shares the
pec deck image. Sharing an illustration never selects both choices.
The assisted pull-up/dip image currently includes its original white background.

Keep filenames exactly as supplied, including `dumbell.webp` and
`sqaut_rack.webp`; stable selection IDs are independent of those filenames.

Selections persist in the onboarding draft and are sent as `equipmentIds` on
registration. Signed-in members can edit them from Today → Profile → Equipment.
The backend retains broad `equipment` categories for existing clients. Exact
IDs take precedence, and Gemini receives them as part of the saved profile.
Legacy combined draft choices expand into their individual selections.
Legacy server profiles without exact IDs require the member to confirm access;
the app does not infer access to specific machines from a broad category.

Validation: `flutter test test/equipment_selection_test.dart` produces real
image previews in `mobile/build/onboarding-equipment-*-preview.png`.
