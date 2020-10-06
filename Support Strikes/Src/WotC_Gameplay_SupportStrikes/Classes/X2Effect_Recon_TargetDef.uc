//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_TargetDefinition.uc
//  AUTHOR:  Joshua Bouscher
//	EDITS:	 E3245
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

// EDITS: Disabled Target Defintion outline while unit is moving, and toggles it back on when the unit has stopped moving

class X2Effect_Recon_TargetDef extends X2Effect_Persistent;

var privatewrite name ReconTargetDefinitionTriggeredEventName;


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
		EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', TargetDefintionListener, ELD_OnStateSubmitted,, UnitState);
		EventMgr.RegisterForEvent(EffectObj, 'UnitMoveFinished', TargetDefintionListener_MoveFinished, ELD_OnStateSubmitted,, UnitState);

		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] SUCCESS, Unit State found and registered for AbilityActivated and UnitMoveFinished! ObjectID:" @ UnitState.ObjectID $ " Name: " $ UnitState.GetFullName() $ " of " $ UnitState.GetMyTemplate().strCharacterName ,, 'WotC_Gameplay_SupportStrikes');
    }
    else `LOG("[" $ self.class $ "::" $ GetFuncName() $ "] ERROR, Could not find UnitState of Object ID: " $ EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID $ "!",, 'WotC_Gameplay_SupportStrikes');
}

function EffectAddedCallback(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local X2EventManager EventMan;
	local XComGameState_Unit UnitState;

	EventMan = `XEVENTMGR;
	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);      //  will be useless for units without unburrow, just add it blindly

		EventMan.TriggerEvent(default.ReconTargetDefinitionTriggeredEventName, kNewTargetState, kNewTargetState, NewGameState);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_TargetDefinition OutlineAction;

	if (EffectApplyResult == 'AA_Success' && XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		OutlineAction = X2Action_TargetDefinition(class'X2Action_TargetDefinition'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		OutlineAction.bEnableOutline = true;
	}
}

//	in theory this effect never gets removed, but just in case
simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_TargetDefinition OutlineAction;

	if (XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		class'X2Action_TargetDefinition'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
	}
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local X2Action_TargetDefinition OutlineAction;

	OutlineAction = X2Action_TargetDefinition(class'X2Action_TargetDefinition'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	OutlineAction.bEnableOutline = true;
}

static function EventListenerReturn TargetDefintionListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability  AbilityContext;
    local XComGameState_Ability         AbilityState;
    local XComGameState_Unit            UnitState;
	local XComWorldData					WorldData;
	local XComGameState_Effect          EffectState;
	local TTile							Tile;
	local int i;
	local XComGameState					NewGameState;

    //    AbilityState of the ability that was just activated.
    AbilityState = XComGameState_Ability(EventData);
	//    Unit that activated the ability.
    UnitState = XComGameState_Unit(EventSource);
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	EffectState = UnitState.GetUnitAffectedByEffectState(default.EffectName);

	if (AbilityState == none || UnitState == none || AbilityContext == none || EffectState == none)
    {
		`LOG("[X2Effect_Recon_TargetDef::" $ GetFuncName() $ "] One or more states are missing!",, 'WotC_Gameplay_SupportStrikes');
		`LOG("AbilityState: " $ AbilityState ,, 'WotC_Gameplay_SupportStrikes');
		`LOG("UnitState: " $ UnitState ,, 'WotC_Gameplay_SupportStrikes');
		`LOG("AbilityContext: " $ AbilityContext ,, 'WotC_Gameplay_SupportStrikes');
		`LOG("EffectState: " $ EffectState,, 'WotC_Gameplay_SupportStrikes');
        return ELR_NoInterrupt;
    }
	
	`LOG("[X2Effect_Recon_TargetDef::" $ GetFuncName() $ "] Move ability activated by the unit:" @ UnitState.GetFullName(),, 'WotC_Gameplay_SupportStrikes');
	
	//	Interrupt stage, before the ability has actually gone through
	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		if (AbilityContext.InputContext.MovementPaths.Length > 0)
		{
			// Trigger additional effect when the ability is activated
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[X2Effect_Recon_TargetDef::" $ GetFuncName() $ "] Enlisting Units to disable Outline");
			NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID);		//	enlist this unit to the build vis function

			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = DisableOutlineVisualizationFn;
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

    return ELR_NoInterrupt;
}

static function EventListenerReturn TargetDefintionListener_MoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Effect          EffectState;
	local XComGameState					NewGameState;

    //    Unit that finished moving.
    UnitState = XComGameState_Unit(EventSource);

    `LOG("[X2Effect_Recon_TargetDef::" $ GetFuncName() $ "] " $ UnitState.GetFullName(),, 'WotC_Gameplay_SupportStrikes');
    
    if (UnitState != none )
    {
		// Trigger additional effect when the ability is activated
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[X2Effect_Recon_TargetDef::" $ GetFuncName() $ "] Enlisting Units to enable Outline");
		NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID);		//	enlist this unit to the build vis function

		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EnableOutlineVisualizationFn;
		`TACTICALRULES.SubmitGameState(NewGameState);
       
    }
    else `LOG("[X2Effect_Recon_TargetDef::" $ GetFuncName() $ "] Failed to retrieve Unit State.",, 'WotC_Gameplay_SupportStrikes');

    return ELR_NoInterrupt;
}

function EnableOutlineVisualizationFn(XComGameState VisualizeGameState)
{
	BuildTargetDefinitionPostVisualization(VisualizeGameState, true);
}

function DisableOutlineVisualizationFn(XComGameState VisualizeGameState)
{
	BuildTargetDefinitionPostVisualization(VisualizeGameState, false);
}

function BuildTargetDefinitionPostVisualization(XComGameState VisualizeGameState, bool bToggleOutline)
{
	local XComGameState_Unit UnitState;
	local X2Action_TargetDefinition OutlineAction;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();
	
		if (!bToggleOutline)
			class'X2Action_TargetDefinition'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		else
		{
			OutlineAction = X2Action_TargetDefinition(class'X2Action_TargetDefinition'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			OutlineAction.bEnableOutline = true;
		}
		
		break;
	}
}

DefaultProperties
{
	EffectName = "ReconTargetDefinition"
	DuplicateResponse = eDupe_Ignore
	EffectAddedFn = EffectAddedCallback
	ReconTargetDefinitionTriggeredEventName = "ReconTargetDefinitionTriggered"
}
