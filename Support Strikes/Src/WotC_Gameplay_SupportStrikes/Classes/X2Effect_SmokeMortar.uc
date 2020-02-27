class X2Effect_SmokeMortar extends X2Effect_SmokeGrenade;

var int AimBonus;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
    local X2EventManager        EventMgr;
    local XComGameState_Unit    UnitState;
    local Object                EffectObj;
    local XComGameStateHistory  History;
 
    History = `XCOMHISTORY;
    EffectObj = EffectGameState;
 
    //  Unit State of unit in smoke
    UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
 
	if (UnitState != none)
	{
		EventMgr = `XEVENTMGR;
 
		//  EventMgr.RegisterForEvent(EffectObj, 'EventID', EventFn, Deferral, Priority, PreFilterObject,, CallbackData);
		//  EffectObj - Effect State of this particular effect.
		//  PreFilterObject - only listen to Events triggered by this object. Typically, UnitState of the unit this effect was applied to.
		//  CallbackData - any arbitrary object you want to pass along to EventFn. Often it is the Effect State so you can access its ApplyEffectParameters in the EventFn.
 
		//  When this Event is triggered (somewhere inside this Effect), the game will display the Flyover of the ability that has applied this effect.
		EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', CleanseSmokeEffectListener, ELD_Immediate,, UnitState);
		EventMgr.RegisterForEvent(EffectObj, 'UnitMoveFinished', CleanseSmokeEffectListener_MoveFinished, ELD_Immediate,, UnitState);

				`LOG("SUCCESS, Unit State found and registered for AbilityActivated and UnitMoveFinished! ObjectID:" @ UnitState.ObjectID $ " Name: " $ UnitState.GetFullName() $ " of " $ UnitState.GetMyTemplate().strCharacterName ,, 'WotC_Gameplay_SupportStrikes');
    }
    else `LOG("ERROR, Could not find UnitState of Object ID: " $ EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID $ "!",, 'WotC_Gameplay_SupportStrikes');
}

static function EventListenerReturn CleanseSmokeEffectListener(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability  AbilityContext;
    local XComGameState_Ability         AbilityState;
    local XComGameState_Unit            UnitState;
	local XComWorldData					WorldData;
	local XComGameState_Effect          EffectState;
	local TTile							Tile;
	local int i;

    //    AbilityState of the ability that was just activated.
    AbilityState = XComGameState_Ability(EventData);
	//    Unit that activated the ability.
    UnitState = XComGameState_Unit(EventSource);
    AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	EffectState = UnitState.GetUnitAffectedByEffectState(default.EffectName);

	if (AbilityState == none || UnitState == none || AbilityContext == none || EffectState == none)
    {
        //    Something went wrong, exit listener.
        return ELR_NoInterrupt;
    }
	
	`LOG("Move ability activated by the unit:" @ UnitState.GetFullName(),, 'WotC_Gameplay_SupportStrikes');

	WorldData = `XWORLD;
	
	//	Interrupt stage, before the ability has actually gone through
	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		for (i = 0; i < AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length; i++)
		{
			Tile = AbilityContext.InputContext.MovementPaths[0].MovementTiles[i];

			if (!WorldData.TileContainsWorldEffect(Tile, class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
			{
				`LOG("Path takes the unit" @ UnitState.GetFullName() @ "outside Smoke on tile #: " @ i @ ", removing effect.",, 'WotC_Gameplay_SupportStrikes');

				EffectState.RemoveEffect(NewGameState, NewGameState, true);
				return ELR_NoInterrupt;
			}
			`LOG("Path DOES NOT take the unit" @ UnitState.GetFullName() @ "outside Smoke. NOT removing effect.",, 'WotC_Gameplay_SupportStrikes');
		}
	}
	else
	{
		// Not in the interrupt stage, ability has been successfully activated.
		//	Move the working code here, if necessary.
	}

	
    return ELR_NoInterrupt;
}
/*

	Effect changes the chance to hit on itself that's given the effect

*/
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Target.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = HitMod;
		ShotMod.Reason = FriendlyName;
		ShotModifiers.AddItem(ShotMod);
	}
}

static function EventListenerReturn CleanseSmokeEffectListener_MoveFinished(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackData)
{
    local XComGameState_Unit            UnitInSmoke;
    local XComGameState_Effect          EffectState;

    //    Unit that finished moving.
    UnitInSmoke = XComGameState_Unit(EventSource);

    `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished:" @ UnitInSmoke.GetFullName(),, 'WotC_Gameplay_SupportStrikes');
    
    if (UnitInSmoke != none )
    {
        if ( !UnitInSmoke.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name) )
        {    
            `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit is not in smoke",, 'WotC_Gameplay_SupportStrikes');

            EffectState = UnitInSmoke.GetUnitAffectedByEffectState(default.EffectName);
            if (EffectState != none)
            {
                `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: removing smoke effect.",, 'WotC_Gameplay_SupportStrikes');

                EffectState.RemoveEffect(NewGameState, NewGameState, true);
            } 
            else `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit had no smoke effect.",, 'WotC_Gameplay_SupportStrikes');
        } 
        else `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit is on a smoked tile.",, 'WotC_Gameplay_SupportStrikes');
    }
    else `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: failed to retrieve Unit State.",, 'WotC_Gameplay_SupportStrikes');

    return ELR_NoInterrupt;
}
/*

	Effect changes the chance to hit to target

*/
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotInfo;

	if (Attacker.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
	{
		//Only melee is immune to smoke's aim malus
		if (!bMelee)
		{
			ShotInfo.ModType = eHit_Success;
			ShotInfo.Value = AimBonus;
			ShotInfo.Reason = FriendlyName;
			ShotModifiers.AddItem(ShotInfo);
		}
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return TargetUnit.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name);
}

static function SmokeGrenadeVisualizationTickedOrRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_UpdateUI UpdateUIAction;

	UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	UpdateUIAction.SpecificID = ActionMetadata.StateObject_NewState.ObjectID;
	UpdateUIAction.UpdateType = EUIUT_UnitFlag_Buffs;
}


DefaultProperties
{
	EffectName = "SmokeMortar"
	DuplicateResponse = eDupe_Allow
	EffectTickedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
	EffectRemovedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
}