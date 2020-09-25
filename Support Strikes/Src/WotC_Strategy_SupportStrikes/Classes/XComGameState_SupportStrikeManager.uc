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
	var name	AbilityTemplateName;
	var StrategyCost	StrikeCost;
	var float	Multiplier;
	var int		Addition;
	var int		MaximumCap;
	structdefaultproperties
	{
		Multiplier = 1.00f;
		Addition  = 0;
		MaximumCap = 3;
	}
};

struct CurrentMonthStrikeUsage
{
	var name	TemplateName;
	var int		Usage;
	var int		MaximumCap;
	structdefaultproperties
	{
		Usage = 0;
	}
};

// Conditional tactical gamestate.
// To speed up loading times, this is only created once the player has purchased certain support strikes that require it.
var StateObjectReference								TacticalGameState;

// Additional Content
var bool												bInstallChosenSupportStrikes;

// Error codes that will restrict usage Support Strikes
var bool												bValid;

// Flags
var bool												bInvalid_HeightClearance;		// Underground restriction
var bool												bInvalid_Misc;					// Restriction for any other reason (One is supported for now)
var bool												bInvalid_RestrictArtillery;		// Restricts any Arty-class Strikes
var bool												bInvalid_RestrictAirSupport;	// Restricts any Airborne Strikes
var bool												bInvalid_NoResources;			// If there is not enough resources to perform any strikes
var bool												bInvalid_PartialResources;		// If there is one or more support strikes that weren't added
var bool												bInvalid_Unknown;				// Unknown reason

// Same as SoldierUnlockTemplates but only carries support strikes
var array<name>											PurchasedSupportStrikes;

// Future implementation
var bool												bChosenHasSupportStrike;
var bool												bADVENTHasSupportStrike;

// Consider making these objectives
var bool												bAircraftUnlocked;
var bool												bIonCannonUnlocked;

// Special bool for Heli Drop In
var bool												bHeliDropInPreLoadUnits;

// When this is implemented, control the condition that causes the ability to appear
var bool												bEnableVagueOrders;

// For post mission project creation
var bool												bIsClassArtillery;
var bool												bIsClassAirCraftAttack;
var bool												bIsClassAirCraftBomber;

// The data type that will bring everything together
var config array<SupportStrikeStruct>					SupportStrikeData;
var privatewrite array<name>							CurrentMissionSupportStrikes;	// Array that's tells the game to add these items to the game if they meet certain requirements.
var privatewrite array<name>							DisabledMissionSupportStrikes;	// Array for support strikes that are invalid. Primary

// This is the original data structure so that it can be reset back to default values whenever possible.
var privatewrite array<CurrentMonthStrikeUsage>			StrikeOriginalMonthUsage;
var array<CurrentMonthStrikeUsage>						StrikeCurrentMonthUsage;		//short vector that stores the current usage of the support strike

//---------------------------------------------------------------------------------------

static function SetUpSupportStrikeManager(XComGameState StartState)
{
	local XComGameState_SupportStrikeManager StrikeMgr;

	foreach StartState.IterateByClassType(class'XComGameState_SupportStrikeManager', StrikeMgr)
	{
		break;
	}

	if (StrikeMgr == none)
	{
		StrikeMgr = XComGameState_SupportStrikeManager(StartState.CreateNewStateObject(class'XComGameState_SupportStrikeManager'));
		// Add the manager class

		`LOG("[" $ GetFuncName() $ "] Installing New Support Strike Manager with Object ID: " $ StrikeMgr.ObjectID,  class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Strategy_SupportStrikes');
		`LOG("[" $ GetFuncName() $ "] SUCCESS... Installed Support Strike Manager.",  class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Strategy_SupportStrikes');
		// Create arrays for month
	}

	StrikeMgr.InitializeCurrentUsage();
}

simulated function InitializeCurrentUsage()
{
	local CurrentMonthStrikeUsage Data;
	local SupportStrikeStruct ResourceCostScaleData;

	// If the dataset is empty, populate it
	if (StrikeCurrentMonthUsage.Length == 0)
	{
		`LOG("Repopulating StrikeCurrentMonthUsage...",,'WotC_Strategy_SupportStrikes');
		foreach SupportStrikeData(ResourceCostScaleData)
		{
			Data.TemplateName	= ResourceCostScaleData.AbilityTemplateName;
			Data.Usage			= 0;
			Data.MaximumCap		= ResourceCostScaleData.MaximumCap;

			`LOG("[" $ GetFuncName() $ "] " $ Data.TemplateName $ ", " $ Data.Usage $ " ," $ Data.MaximumCap ,,'WotC_Strategy_SupportStrikes');

			StrikeCurrentMonthUsage.AddItem(Data);
		}

		//Save the original values for swapping during end of months
		StrikeOriginalMonthUsage = StrikeCurrentMonthUsage;

		return;
	}
}

//---------------------------------------------------------------------------------------

static function OnPreMission(XComGameState NewGameState, XComGameState_SupportStrikeManager SupportStrikeMgr)
{
	local int									Index;
	local name									UnlockName;
	local XComGameState_SupportStrike_Tactical	StrikeTactical;

	`LOG("[" $ GetFuncName() $ "] Enlisting Support Strike Manager to tactical" ,class'X2Helpers_MiscFunctions'.static.Log(true),'WotC_Strategy_SupportStrikes');

	//Enlist itself into the tactical state so we don't lose our object when reloading a save
	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	//Safeguard: reset the arrays if it hasn't already.
	if (SupportStrikeMgr.CurrentMissionSupportStrikes.Length > 0)
	{
		SupportStrikeMgr.CurrentMissionSupportStrikes.Length = 0;
		SupportStrikeMgr.DisabledMissionSupportStrikes.Length = 0;
	}

	foreach SupportStrikeMgr.PurchasedSupportStrikes(UnlockName)
	{
		Index = SupportStrikeMgr.SupportStrikeData.Find('GTSTemplate', UnlockName);
		if (Index != INDEX_NONE)
		{
			//Test if we have enough intel to use a support strike
			if ( SupportStrikeMgr.EnoughIntelForStrike(SupportStrikeMgr.SupportStrikeData[Index].AbilityTemplateName) )
			{
				SupportStrikeMgr.CurrentMissionSupportStrikes.AddItem(SupportStrikeMgr.SupportStrikeData[Index].ItemToGive);
				`LOG("[" $ GetFuncName() $ "] Adding " $ SupportStrikeMgr.SupportStrikeData[Index].AbilityTemplateName $ " to the current mission",true,'WotC_Strategy_SupportStrikes');

				// Special case, if the added support strike is the heli drop in, initialize and enlist the object into tactical
				// Here because of quicker runtime rather than having to go through the array again
				if (SupportStrikeMgr.SupportStrikeData[Index].AbilityTemplateName == 'Ability_Support_Air_Def_HeliDropIn_Stage1')
				{

					`LOG("[" $ GetFuncName() $ "] Enlisting Strike Tactical object to tactical" ,class'X2Helpers_MiscFunctions'.static.Log(true),'WotC_Strategy_SupportStrikes');
					StrikeTactical = XComGameState_SupportStrike_Tactical(`XCOMHISTORY.GetGameStateForObjectID(SupportStrikeMgr.TacticalGameState.ObjectID));
					StrikeTactical = XComGameState_SupportStrike_Tactical(NewGameState.ModifyStateObject(class'XComGameState_SupportStrike_Tactical', StrikeTactical.ObjectID));
				}
			}
			else
				SupportStrikeMgr.DisabledMissionSupportStrikes.AddItem(SupportStrikeMgr.SupportStrikeData[Index].AbilityTemplateName);
		}
	}

	// If no support strikes were added, flag it
	if ( (SupportStrikeMgr.PurchasedSupportStrikes.Length != 0 && SupportStrikeMgr.CurrentMissionSupportStrikes.Length == 0) )
		SupportStrikeMgr.bInvalid_NoResources = true;

	// If some support strikes were added but not all of them, flag it
	if ( SupportStrikeMgr.PurchasedSupportStrikes.Length != 0 && 
		(SupportStrikeMgr.CurrentMissionSupportStrikes.Length > 0 && 
		(SupportStrikeMgr.CurrentMissionSupportStrikes.Length != SupportStrikeMgr.PurchasedSupportStrikes.Length)) )
		SupportStrikeMgr.bInvalid_PartialResources = true;

}

//---------------------------------------------------------------------------------------
static function OnExitPostMissionSequence(XComGameState NewGameState)
{
	local XComGameStateHistory								History;
	local XComGameState_HeadquartersXCom					XComHQ;
	local int												Index;
	local XComGameState_Unit								UnitState;
	local StateObjectReference								UnitRef;
	local array<XComGameState_Item>							AllItems;
	local XComGameState_Item								Item;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if ( SupportStrikeMgr.CurrentMissionSupportStrikes.Length > 0 )
	{
		SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

		//If previous map had no height clearance, then flip the flag and do nothing else
		if ( SupportStrikeMgr.bInvalid_HeightClearance )
		{
			`LOG("[" $ GetFuncName() $ "] Invalid location flag was raised! Resetting flag for next mission." , class'X2Helpers_MiscFunctions'.static.Log(true),'WotC_Strategy_SupportStrikes');
			SupportStrikeMgr.bInvalid_HeightClearance = false;
		}
		else
		{
			//Remove flags
			SupportStrikeMgr.bValid = false;
			SupportStrikeMgr.bInvalid_NoResources = false;
			SupportStrikeMgr.bInvalid_PartialResources = false;

			//Disable Vague Orders
			SupportStrikeMgr.bEnableVagueOrders = false;

			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

			// Another safety check to make sure we aren't modifying states improperly
			if (SupportStrikeMgr.CurrentMissionSupportStrikes.Length > 0)
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
							Index = SupportStrikeMgr.CurrentMissionSupportStrikes.Find(Item.GetMyTemplate().DataName);
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

//---------------------------------------------------------------------------------------

// Calculates the cost of the support strike
// Returns a value or -1 if error
simulated function int GrabStrikeCost(name TemplateName, optional bool VerifyWithCurrentMonth = false)
{
	local int Idx;

	if (SupportStrikeData.Length == 0)
	{
		`LOG("[" $ GetFuncName() $ "] Error, SupportStrikeData Length is 0!", class'X2Helpers_MiscFunctions'.static.Log(,true), 'WotC_Strategy_SupportStrikes');
		return -1;
	}

	//Search for the Template within our array
	Idx = SupportStrikeData.Find('AbilityTemplateName', TemplateName);

	//Handle missing index case
	if (Idx == INDEX_NONE)
		return -2;

	// Fail if there's a mismatch with the array
	if (VerifyWithCurrentMonth && (StrikeCurrentMonthUsage[Idx].TemplateName != SupportStrikeData[Idx].AbilityTemplateName))
	{
		`LOG("[" $ GetFuncName() $ "] Did not pass verification, " $ SupportStrikeData[Idx].AbilityTemplateName $ " is not " $ StrikeCurrentMonthUsage[Idx].TemplateName, class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Strategy_SupportStrikes');
		return -3;
	}

	return Idx;
}

// Calculates the cost of the support strike, only calculates a basic integer
// Returns a value or -1 if error
simulated function int CalculateStrikeCost_Simple(name TemplateName, optional SupportStrikeStruct ResourceCost, optional int Usage = 0, optional int CheckCurrentUsage = 1)
{
	local int Idx;
	//Get our data
	if (ResourceCost.AbilityTemplateName == '')
	{
		Idx = GrabStrikeCost(TemplateName, true);
		
		//If above function fails, return -1
		if (Idx == INDEX_NONE)
		{
			`LOG("[" $ GetFuncName() $ "] Error, could not find " $ TemplateName, class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Strategy_SupportStrikes');
			return Idx;
		}

		ResourceCost = SupportStrikeData[Idx];
	}

	// For calculating costs in the future, make sure not to exceed our limit
	if ( (Usage + StrikeCurrentMonthUsage[Idx].Usage) > StrikeCurrentMonthUsage[Idx].MaximumCap )
		Usage = StrikeCurrentMonthUsage[Idx].MaximumCap;
	
	//Perform the calculation
	return ( ResourceCost.StrikeCost.ResourceCosts[0].Quantity + (ResourceCost.StrikeCost.ResourceCosts[0].Quantity * (ResourceCost.Multiplier * ((StrikeCurrentMonthUsage[Idx].Usage * CheckCurrentUsage) + Usage))) + (ResourceCost.Addition * (StrikeCurrentMonthUsage[Idx].Usage + Usage)) );
}

// Calculates the cost of the support strike and returns a StrategyCost object
simulated function StrategyCost CalculateStrikeCost_StrategyCost(name TemplateName)
{
	local int				Idx;
	local StrategyCost		RetStrCost;

	Idx = GrabStrikeCost(TemplateName);

	//Create strategy cost object
	RetStrCost = SupportStrikeData[Idx].StrikeCost;
	RetStrCost.ResourceCosts[0].Quantity = CalculateStrikeCost_Simple(TemplateName, SupportStrikeData[Idx]);

	return RetStrCost;
}

//---------------------------------------------------------------------------------------

simulated function int GetCurrentStrikeUsage(name AbilityTemplateName)
{
	local int				Idx;

	//Search for the Template within our array
	Idx = StrikeCurrentMonthUsage.Find('TemplateName', AbilityTemplateName);

	//Handle missing index case
	if (Idx == INDEX_NONE)
		return -1;

	return Idx;
}

simulated function AdjustStrikeUsage(name TemplateName)
{
	local int				Idx;
	local int				UsageCount;

	if (TemplateName == '')
	{
		`LOG("[" $ GetFuncName() $ "] ERROR, TemplateName was empty!" , class'X2Helpers_MiscFunctions'.static.Log(,true),'WotC_Strategy_SupportStrikes');
		return;
	}

	Idx = GetCurrentStrikeUsage(TemplateName);

	UsageCount = StrikeCurrentMonthUsage[Idx].Usage + 1;

	// Check if the usage has hit the cap, if not, assign the value to the usage
	if (UsageCount <= StrikeCurrentMonthUsage[Idx].MaximumCap)
		StrikeCurrentMonthUsage[Idx].Usage = UsageCount;

	`LOG("[" $ GetFuncName() $ "] " $ StrikeCurrentMonthUsage[Idx].TemplateName $ " usage is now at " $ StrikeCurrentMonthUsage[Idx].Usage $ " out of " $ StrikeCurrentMonthUsage[Idx].MaximumCap , class'X2Helpers_MiscFunctions'.static.Log(true),'WotC_Strategy_SupportStrikes');
}

//---------------------------------------------------------------------------------------

// Check if there is enough intel for a particular strike. 
// Requires the ability template
simulated function bool EnoughIntelForStrike(name AbilityTemplateName)
{
	local XComGameState_HeadquartersXCom		XComHQ;
	local int									FinalStrikeCost, IntelHQ;

	//Grab XCom HQ
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	IntelHQ = XComHQ.GetIntel();

	FinalStrikeCost = CalculateStrikeCost_Simple(AbilityTemplateName);

	// If we have more or an equal amount of intel than the final strike cost
	if (IntelHQ >= FinalStrikeCost)
		return true;

	return false;
}


//---------------------------------------------------------------------------------------