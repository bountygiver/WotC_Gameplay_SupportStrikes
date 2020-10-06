// This class draws the range indicator on the unit above FOW with a random starting point. The effect does not get cleansed when a unit walks out of FOW but instead the ring is hidden until the unit walks back into FOW.

class X2Effect_Recon extends X2Effect_Persistent config(GameData);

var() int			RangeRingRadius;
var() float			PFXScale;
var() bool			bUseSightRadius;			//Disregards above if set. Will end up using sight radius for its rings, but can still be affected by the delta.
var() vector		Offset;						// Only X and Y values will be considered
var() string		PFX;

// Apply the ring calculations on the unit
//simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
//{
//	local XComGameState_Unit	UnitState;
//	local float					RangeRingRadiusUnrealUnits, RadiusTotal;
//	local XComWorldData			World;
//	local vector				UnitLocation;
//	local XComUnitPawn			TargetUnitPawn; 
//	local Object				Obj;
//	local StaticMesh			InstRingMesh;
//
//	UnitState = XComGameState_Unit(kNewTargetState);
//
//	if (UnitState != none)
//	{
//		
//		if (bUseSightRadius)
//		{
//			//Convert sight radius to unreal units
//			RangeRingRadiusUnrealUnits = UnitState.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_StepSize;
//			RadiusTotal = RangeRingRadiusUnrealUnits * RangeRingRadiusDelta;
//
//			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Generating ring for Unit " $ UnitState.GetMyTemplateName() $ " with size of " $ RadiusTotal, , 'WotC_Gameplay_SupportStrikes');
//		}
//		else
//		{
//			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Generating Ring using Ring Radius: " $ RangeRingRadius, , 'WotC_Gameplay_SupportStrikes');
//			RangeRingRadiusUnrealUnits = RangeRingRadius * class'XComWorldData'.const.WORLD_StepSize;
//			RadiusTotal = RangeRingRadiusUnrealUnits * RangeRingRadiusDelta;
//		}
//
//		World = `XWORLD;
//
//		UnitLocation = World.GetPositionFromTileCoordinates(UnitState.TileLocation);
//
//		// Instantate a new ring mesh
//		Obj = `CONTENT.RequestGameArchetype(RingMesh);
//
//		if (Obj == none)
//			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Could not find Static Mesh: " $ RingMesh, , 'WotC_Gameplay_SupportStrikes');
//
//		if ( Obj != none && !Obj.IsA('StaticMesh') )
//			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] WARNING, Object: " $ RingMesh $ " is not of type StaticMesh! This could lead into a crash!", , 'WotC_Gameplay_SupportStrikes');
//		else if ( Obj != none && Obj.IsA('StaticMesh') )
//			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Object: " $ RingMesh $ " is of type StaticMesh", , 'WotC_Gameplay_SupportStrikes');
//
//		InstRingMesh = StaticMesh(Obj);
//
//
//		// Get our pawn
//		TargetUnitPawn = XGUnit(UnitState.GetVisualizer()).GetPawn();
//
//		//Apply rings to unit pawn
//		TargetUnitPawn.AttachRangeIndicator(RadiusTotal, InstRingMesh);
//
//		// Move the ring to our new location
//		UnitLocation = TargetUnitPawn.RangeIndicator.GetPosition();
//
//		// Generate new offset for the ring translation
//		UnitLocation.X += World.WORLD_StepSize * `SYNC_RAND(-1 * Offset.X, Offset.X);
//		UnitLocation.Y += World.WORLD_StepSize * `SYNC_RAND(-1 * Offset.Y, Offset.Y);
//
//		TargetUnitPawn.RangeIndicator.SetTranslation(UnitLocation);
//
//		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Generated Ring on Unit " $ UnitState.GetMyTemplateName() $ " with Object ID: " $ UnitState.ObjectID, , 'WotC_Gameplay_SupportStrikes');
//		
//		//Disable rings for units that are visible
//		if ( class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(UnitState.ObjectID) )
//		{
//			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Unit is Visible to XCom. Hiding Ring", , 'WotC_Gameplay_SupportStrikes');
//
//			TargetUnitPawn.RangeIndicator.SetHidden(true);
//		}
//	}
//
//	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
//}

// At start of each turn, hide the indicator BUT do not cleanse the effect unless dead
function bool ReconEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit	AppliedUnit;
	local XComUnitPawn			TargetUnitPawn; 

	AppliedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (AppliedUnit == none)
	{
		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] WARNING, Unit previously given effect no longer exist! Cleansing effect" , ,'WotC_Gameplay_SupportStrikes');
		return true; // no target, effect is done
	}
	
	if (AppliedUnit.IsDead())
	{
		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Unit is dead, cleansing effect" , , 'WotC_Gameplay_SupportStrikes');
		return true; // target is dead, effect is done
	}

	if (kNewEffectState.iTurnsRemaining == 0)
	{
		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] No turns left for effect!" , , 'WotC_Gameplay_SupportStrikes');
		return true; // effect expired, effect is done
	}

	// Update The Effect State with new position
	//kNewEffectState.ApplyEffectParameters.AbilityInputContext.TargetLocation[0] = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Perk is still active for " $ kNewEffectState.iTurnsRemaining, , 'WotC_Gameplay_SupportStrikes');
	return false; // effect persists
}

// Add visualization
// Drop a breadcrumb PFX on the ground of the unit
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_PlayEffect_Advanced PlayEffectAction;
	local XComGameState_Unit UnitState;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState != none)
	{
		if (bUseSightRadius)
		{
			PFXScale = UnitState.GetVisibilityRadius();
		}
	}

	PlayEffectAction = X2Action_PlayEffect_Advanced(class'X2Action_PlayEffect_Advanced'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Particle PFX to add: " $ PFX, , 'WotC_Gameplay_SupportStrikes');

	PlayEffectAction.AttachToUnit = true;
	PlayEffectAction.EffectName = PFX;
	PlayEffectAction.EffectScale = PFXScale;
//	PlayEffectAction.EffectLocation = TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocation[0];
//	PlayEffectAction.AttachToSocketName = 'CIN_Root';
//	PlayEffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
	PlayEffectAction.bWaitForCompletion = false;
}

// Remove Visualization
simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlayEffect_Advanced PlayEffectAction;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	PlayEffectAction = X2Action_PlayEffect_Advanced( class'X2Action_PlayEffect_Advanced'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Particle PFX to remove: " $ PFX, , 'WotC_Gameplay_SupportStrikes');

	PlayEffectAction.AttachToUnit = true;
	PlayEffectAction.EffectName = PFX;
	PlayEffectAction.EffectScale = PFXScale;
	PlayEffectAction.AttachToSocketName = 'CIN_Root';
	PlayEffectAction.AttachToSocketsArrayName = 'BoneSocketActor';

	PlayEffectAction.bStopEffect = true;
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Called!" , ,'WotC_Gameplay_SupportStrikes');
	super.AddX2ActionsForVisualization_Sync(VisualizeGameState, ActionMetadata);
	if(XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		// Test and update if the unit is NOT visible to XCom
		// We will not have to instatate the particle component on loading a save while the effect is active and the unit is visible
		if ( !class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(ActionMetadata.StateObject_NewState.ObjectID) )
		{
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] XCom no longer sees us, toggling PFX!" , , 'WotC_Gameplay_SupportStrikes');

			// Update visualizer on the unit
			AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
		}
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
	super.AddX2ActionsForVisualization_Tick(VisualizeGameState, ActionMetadata, TickIndex, EffectState);
	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Called! Tick Index: " $ TickIndex, ,'WotC_Gameplay_SupportStrikes');
	if(XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		// Test and update if the unit is visible to XCom or not
		if ( class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(ActionMetadata.StateObject_NewState.ObjectID) )
		{
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] XCom sees us, removing PFX!" , ,'WotC_Gameplay_SupportStrikes');

			// Update visualizer on the unit
			AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, 'AA_Success', EffectState);
		}
		else
		{
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] XCom no longer sees us, toggling PFX!" , , 'WotC_Gameplay_SupportStrikes');

			// Update visualizer on the unit
			AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
		}
	}
}

DefaultProperties
{
	bTickWhenApplied = true;
	EffectName = "ReconEffect";
	DuplicateResponse = eDupe_Ignore;
	EffectTickedFn = ReconEffectTicked;
	RescueRingRadius = 3.0f;
}