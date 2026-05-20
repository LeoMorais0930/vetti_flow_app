# Implementation Plan - Production, Test, and Support Screen Updates

This plan outlines the changes to improve production stage transitions, split defective items in the Test screen, and add requisition/editing features to the Support screen.

## User Review Required

> [!IMPORTANT]
> - **Order Splitting:** In the Test screen, when an order has both conforming and non-conforming items, it will be split into two separate order entries in the system (sharing the same OP number) to track their progress in different stages (next stage vs. support).
> - **Sync Simulation:** The "Edit Value" in Support will include a 60-second "Protheus Sync" simulation.

## Proposed Changes

### [Models & Services]

#### [figma_models.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/models/figma_models.dart)
- Add `lastSignature` and `originStage` fields to `FigmaOrder` to track who moved it and from where.
- Add `Refused` and `Approved` status to `RequisitionStatus`.
- Update `FigmaRequisition` to include `requesterName` and `originStage`.

#### [figma_service.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/services/figma_service.dart)
- Implement `addRequisition` and `updateRequisition` methods.
- Implement logic to handle order updates and stage transitions more robustly.
- Add initial dummy data for requisitions if needed.

---

### [Screens]

#### [generic_production_screen.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/screens/figma/generic_production_screen.dart)
- Update `_handleFinalize` to record the user's signature and the current stage before moving to the next one.
- Ensure `FigmaService` is used for all operations.

#### [teste_screen.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/screens/figma/teste_screen.dart)
- Replace mock data with `FigmaService`.
- Implement new "Finalize" logic:
    - Dialog to input quantity of Approved (Conformes) and Defective (Não Conformes).
    - Move Approved items to the next stage.
    - Move Defective items to `suporte` stage.
    - If both exist, the order is split.

#### [suporte_screen.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/screens/figma/suporte_screen.dart)
- Replace mock data with `FigmaService`.
- Add "REQUISITAR" button:
    - Opens a dialog to create a requisition (Code, Description, Name, Quantity).
- Add "HISTÓRICO DE REQUISIÇÕES" button/view:
    - List of requisitions and their status (Pending, Approved, Refused).
- Add "EDITAR VALOR" button:
    - Allows changing the quantity of an order.
    - Shows the 60s "Syncing with Protheus" timer before applying the change.

#### [almoxarifado_screen.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/screens/figma/almoxarifado_screen.dart)
- Add a new section or tab to manage "Support Requisitions".
- Allow Vera to Approve or Refuse requisitions.

#### [widgets.dart](file:///C:/Users/Leonardo Morais/Desktop/vetti_flow_app/lib/screens/figma/widgets.dart)
- Potentially update cards to display the "Signature" (e.g., "Assinado por [User] em [Stage]").

---

## Verification Plan

### Automated Tests
- No automated tests currently exist for this feature set, but I will perform manual verification.

### Manual Verification
1. **Signature Flow:**
   - Log in as Carlos (Gravação).
   - Finalize an OP.
   - Log in as Ana (Soldagem).
   - Verify if the OP shows "Vindo de Gravação assinado por Carlos".
2. **Test Screen Split:**
   - Log in as Joao (Teste).
   - Select an OP of 100 units.
   - Mark 90 as Approved and 10 as Defective.
   - Verify that 90 units are now in the next stage (Embalagem).
   - Verify that 10 units are now in the Support screen.
3. **Support Requisition:**
   - Log in as Lucas (Suporte).
   - Create a requisition for "Resistor 10k", qty 50.
   - Verify it appears as "Pendente" in the history.
   - Log in as Vera (Almoxarifado).
   - Approve the requisition.
   - Log back as Lucas and verify it is "Aprovada".
4. **Edit Value in Support:**
   - Log in as Lucas (Suporte).
   - Edit an OP's quantity.
   - Verify the 60s timer appears.
   - After 60s, verify the quantity is updated.
