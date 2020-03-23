//---------------------------------------------------------------------------------------
// FILE:	XComGameState_SupportStrikeManager
// AUTHOR:	E3245
// DESC:	Main manager that controls all aspects of Support Strikes
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_SupportStrikeManager extends XComGameState_BaseObject config(GameData);

struct SupportStrikeStruct
{
	var name GTSTemplate;
	var name Category;
	var name ItemToGive;
};

struct CategoryCooldown
{
	var name Category;
	var int DurationHours;
};

//Copy of this struct from X2StrategyElement_GTSUnlocks_SupportStrikes
struct ResourceCostScale
{
	var name	TemplateName;
	var StrategyCost	StrikeCost;
	var float	Multiplier;
	var int		Addition;
	structdefaultproperties
	{
		Multiplier = 1.00f;
		Addition  = 0;
	}
};

// Additional Content
var bool												bInstallChosenSupportStrikes;

// Error codes that will restrict usage Support Strikes
var bool												bValid;
var bool												bInvalid_HeightClearance;		// Underground restriction
var bool												bInvalid_Misc;					// Restriction for any other reason (One is supported for now)
var bool												bInvalid_RestrictArtillery;		// Restricts any Arty-class Strikes
var bool												bInvalid_RestrictAirSupport;	// Restricts any Airborne Strikes
var bool												bInvalid_Unknown;

// Same as SoldierUnlockTemplates but only carries support strikes
// Must be flushed after every end of mission
var array<name>											PurchasedSupportStrikes;

var bool												bChosenHasSupportStrike;
var bool												bADVENTHasSupportStrike;

// Consider making these objectives
var bool												bAircraftUnlocked;
var bool												bIonCannonUnlocked;

// Special bool for Heli Drop In
var bool												bHeliDropInPreLoadUnits;
var bool												bEnableVagueOrders;

// For post mission project creation
var bool												bIsClassArtillery;
var bool												bIsClassAirCraftAttack;
var bool												bIsClassAirCraftBomber;

// The data type that will bring everything together
var config array<SupportStrikeStruct>					SupportStrikeData;
var config array<CategoryCooldown>						CategoryCooldowns;

// This array is not allowed to be modified by any means!
var const config array<ResourceCostScale>				ScaledSupportStrikeCosts;
var array<ResourceCostScale>							CurrentMonthAbilityIntelCost;

//---------------------------------------------------------------------------------------
static function OnPreMission(XComGameState NewGameState)
{
	local XComGameStateHistory								History;
	local XComGameState_HeadquartersXCom					XComHQ;
	local array<X2SoldierUnlockTemplate>					UnlockTemplates;
	local X2SoldierUnlockTemplate							UnlockTemplate;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	//Gather unlock templates and add them to the Manager
	UnlockTemplates = XComHQ.GetActivatedSoldierUnlockTemplates();

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	// If this array is empty (usually if the mod is first installed or updated), copy the array
	if (SupportStrikeMgr.CurrentMonthAbilityIntelCost.Length == 0)
		SupportStrikeMgr.CurrentMonthAbilityIntelCost = class'XComGameState_SupportStrikeManager'.default.ScaledSupportStrikeCosts;

	foreach UnlockTemplates(UnlockTemplate)
	{

		if		(	UnlockTemplate.DataName == 'GTSUnlock_Artillery_Off_MortartStrike_HE_T1' ||
					UnlockTemplate.DataName == 'GTSUnlock_Artillery_Def_MortartStrike_SMK_T1' ||
					UnlockTemplate.DataName == 'GTSUnlock_Orbital_Off_IonCannon_T1'
				)
		{
			`LOG("[OnPreMission()] Found Template: " $ UnlockTemplate.DataName ,,'WotC_Gameplay_SupportStrikes');
			SupportStrikeMgr.PurchasedSupportStrikes.AddItem(UnlockTemplate.DataName);
		}

		if		( UnlockTemplate.DataName == 'GTSUnlock_Air_Def_HeliDropIn_T1' )
		{
			`LOG("[OnPreMission()] Found Template: " $ UnlockTemplate.DataName ,,'WotC_Gameplay_SupportStrikes');
			SupportStrikeMgr.PurchasedSupportStrikes.AddItem(UnlockTemplate.DataName);
			SupportStrikeMgr.bHeliDropInPreLoadUnits = true;
		}
	}
	
	//If the player has not purchased any strikes, then flag it
	if ( SupportStrikeMgr.PurchasedSupportStrikes.Length == 0 )
		`LOG("[OnPreMission()] Player has no Strikes" ,,'WotC_Gameplay_SupportStrikes');
}
//---------------------------------------------------------------------------------------
static function OnExitPostMissionSequence(XComGameState NewGameState)
{
	local XComGameStateHistory								History;
	local XComGameState_HeadquartersXCom					XComHQ;
	local XComGameState_HeadquartersProjectStrikeDelay		StrikeDelayProject;
	local int												Index;
	local XComGameState_Unit								UnitState;
	local StateObjectReference								UnitRef;
	local array<XComGameState_Item>							AllItems;
	local XComGameState_Item								Item;
	local name												UnlockName;
	local array<name>										ItemNames;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local int												IndexCooldown;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if ( SupportStrikeMgr.PurchasedSupportStrikes.Length > 0 )
	{
		SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

		//If previous map had no height clearance, then flip the flag and do nothing else
		if ( SupportStrikeMgr.bInvalid_HeightClearance )
		{
			`LOG("[OnExitPostMissionSequence()] Invalid location flag was raised! Resetting flag for next mission." ,,'WotC_Strategy_SupportStrikes');
			SupportStrikeMgr.bInvalid_HeightClearance = false;
		}
		else
		{
			SupportStrikeMgr.bValid = false;

			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

			foreach SupportStrikeMgr.PurchasedSupportStrikes(UnlockName)
			{
				XComHQ.RemoveSoldierUnlockTemplate(UnlockName);
				Index = SupportStrikeMgr.SupportStrikeData.Find('GTSTemplate', UnlockName);
				if (Index != INDEX_NONE)
				{
					ItemNames.AddItem(SupportStrikeMgr.SupportStrikeData[Index].ItemToGive);
				}
				else
					`LOG("[OnExitPostMissionSequence()] " $ UnlockName $ " was not found.",,'WotC_Strategy_SupportStrikes');
			}

			//Flush the purchased GTSes
			SupportStrikeMgr.PurchasedSupportStrikes.Length = 0;

			//Disable Vague Orders
			SupportStrikeMgr.bEnableVagueOrders = false;

			// Another safety check to make sure we aren't modifying states improperly
			if (ItemNames.Length > 0)
			{
				//CHeck all units in the squad and remove the appropriate items
				foreach XComHQ.Squad(UnitRef)
				{
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
					if (UnitState != none)
					{
						UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
						AllItems = UnitState.GetAllInventoryItems(NewGameState, true);

						foreach AllItems(Item)
						{
							Index = ItemNames.Find(Item.GetMyTemplate().DataName);
							if  ( Index != INDEX_NONE ) 
							{
								UnitState.RemoveItemFromInventory(Item, NewGameState);
							}
						}
					}
				}
			}
		}
	}
}