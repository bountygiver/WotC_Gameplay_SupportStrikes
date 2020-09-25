//---------------------------------------------------------------------------------------
//
// FILE:	X2DownloadableContentInfo_*
// AUTHOR:	E3245
// DESC:	Typical X2DownloadableContentInfo that does a wide variety of functions
//
//---------------------------------------------------------------------------------------
class X2DownloadableContentInfo_WotC_SupportStrikes extends X2DownloadableContentInfo config (GameData);

var config bool bLogAll;
var config bool bLogErrors;
var config bool bLogInform;
var config bool bChaosMode;				//For those that want to turn the game into chaos

var config array<name> GTSUnlocksTemp;

var config array<string> CinematicMaps;

var config		array<name>		arrAACodes;
var localized	array<string>	arrAAStrings;

//Simple logging function
static function bool Log(optional bool bIsErrorMsg=false, optional bool bIsInformMsg=false)
{
	if (!default.bLogAll)
		if (bIsErrorMsg && !default.bLogErrors)
			return false;
		if (bIsInformMsg && !default.bLogInform)
			return false;

	return true;
}

//Markup stuff
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;

	Type = name(InString);

	switch(Type)
	{
	case 'MORTARSTRIKE_SMK_HITMOD':
		OutString = string(class'X2Ability_MortarStrikes'.default.MortarStrike_SMK_HitMod);
		return true;
	case 'MORTARSTRIKE_SMK_AIMMOD':
		OutString = string(class'X2Ability_MortarStrikes'.default.MortarStrike_SMK_AimMod);
		return true;
	}
	return false;
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_SupportStrikeManager StrikeMgr;

	// Add the manager class
	StrikeMgr = XComGameState_SupportStrikeManager(StartState.CreateNewStateObject(class'XComGameState_SupportStrikeManager'));
	`LOG("[InitializeSupportStrikeManager()] Installing Support Strike Manager with Object ID: " $ StrikeMgr.ObjectID, Log(,true),'WotC_Gameplay_SupportStrikes');
	`LOG("[InitializeSupportStrikeManager()] SUCCESS... Installed Support Strike Manager.", Log(,true),'WotC_Gameplay_SupportStrikes');
}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// </summary>
static event OnPreMission(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_SupportStrikeManager SupportStrikeMgr;
	

	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if (SupportStrikeMgr != none)
	{
		//Check what Support Strikes are purchased before missions
		class'XComGameState_SupportStrikeManager'.static.OnPreMission(NewGameState);
	}
}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{
	local XComGameState NewGameState;
	local XComGameState_SupportStrikeManager SupportStrikeMgr;
	
	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if (SupportStrikeMgr != none)
	{
		//Primary driver for removing Support Strikes post-mission
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Support Strike: OnExitPostMissionSequence() Update");
		class'XComGameState_SupportStrikeManager'.static.OnExitPostMissionSequence(NewGameState);

		if (NewGameState.GetNumGameStateObjects() > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
	}
}

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	InitializeSupportStrikeManager();
	RemoveItemsFromHQ();
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	InitializeSupportStrikeManager();
	RemoveItemsFromHQ();
}

//
// On post templates event that allows you to make changes to templates
// Each section is moved to their own function in X2Helpers_PostTemplateModifications.uc
//
static event OnPostTemplatesCreated()
{
	AddAcademyUnlocks();
	UpdateAbilityAvailabilityStrings();
	class'X2Helpers_SupportStrikes'.static.OnPostCharacterTemplatesCreated();
}

// Setup Display Strings for new AbilityAvailabilityCodes (the localized strings that tell you why an ability fails a condition)
static function UpdateAbilityAvailabilityStrings()
{
    local X2AbilityTemplateManager    AbilityTemplateManager;
    local int                        i, idx;

    AbilityTemplateManager = X2AbilityTemplateManager(class'Engine'.static.FindClassDefaultObject("XComGame.X2AbilityTemplateManager"));

    i = AbilityTemplateManager.AbilityAvailabilityCodes.Length - AbilityTemplateManager.AbilityAvailabilityStrings.Length;

    // If there are more codes than strings, insert blank strings to bring them to equal before adding our new codes
    if (i > 0)
    {
        for (idx = 0; idx < i; idx++)
        {
            AbilityTemplateManager.AbilityAvailabilityStrings.AddItem("");
        }
    }

    // If there are more strings than codes, cut off the excess before adding our new codes
    if (i < 0)
    {
        AbilityTemplateManager.AbilityAvailabilityStrings.Length = AbilityTemplateManager.AbilityAvailabilityCodes.Length;
    }

    // Append new codes and strings to the arrays
    for (idx = 0; idx < default.arrAACodes.Length; idx++)
    {
        AbilityTemplateManager.AbilityAvailabilityCodes.AddItem(default.arrAACodes[idx]);
        AbilityTemplateManager.AbilityAvailabilityStrings.AddItem(default.arrAAStrings[idx]);
    }
}



//
// Given a set of academy unlock templates, removes the templates from being shown in the game.
//
static function AddAcademyUnlocks()
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local X2FacilityTemplate GTSTemplate;
	local name				 GTSNames;

	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();;
	GTSTemplate = X2FacilityTemplate(StrategyTemplateManager.FindStrategyElementTemplate('OfficerTrainingSchool'));

	if (GTSTemplate == none)
		return;

	foreach default.GTSUnlocksTemp(GTSNames)
		GTSTemplate.SoldierUnlockTemplates.AddItem(GTSNames);

	//Printout all GTS Unlocks
//	foreach GTSTemplate.SoldierUnlockTemplates(GTSNames)
//		`LOG("[AddAcademyUnlocks()] Unlockable In GTS: " $ GTSNames,,'WotC_Gameplay_SupportStrikes');
}

// Transition patch to slowly remove items from the game

static function RemoveItemsFromHQ()
{
	local XComGameStateHistory					History;
	local XComGameState							NewGameState;
	local XComGameState_HeadquartersXCom		XComHQ;
	local XComGameState_Item					DelItemState;
	local name									ItemName;
	local array<name>							ItemsToRemove;

	//Fill out local array with my stuff
	ItemsToRemove.AddItem('Support_Artillery_Defensive_MortarStrike_SMK_T1');
	ItemsToRemove.AddItem('Support_Artillery_Offensive_MortarStrike_HE_T1');
	ItemsToRemove.AddItem('Support_Space_Offensive_IonCannon_T1');

    History = `XCOMHISTORY;
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("WotC_Gameplay_SupportStrikes: Remove Items. No Refunds.");
    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
    NewGameState.AddStateObject(XComHQ);

	foreach ItemsToRemove(ItemName)
	{
		DelItemState = XComHQ.GetItemByName(ItemName);
		if (DelItemState != none)
		{
			`LOG("[RemoveItemsFromHQ()] Deleting Item " $ ItemName $ " with QTY: " $ DelItemState.Quantity,Log(,true),'WotC_Gameplay_SupportStrikes');

			NewGameState.RemoveStateObject(DelItemState.ObjectID);

			XComHQ.RemoveItemFromInventory(NewGameState, DelItemState.GetReference(), DelItemState.Quantity);	

			`LOG("[RemoveItemsFromHQ()] SUCCESS, Deleted Item." ,Log(,true),'WotC_Gameplay_SupportStrikes');
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function InitializeSupportStrikeManager()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_SupportStrikeManager StrikeMgr;

	// Don't attempt to install a manager in TQL/Skirmish/Ladder/Challenge Mode
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
		return;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Support Strike: Initialize Manager");

	StrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager', true));
	if (StrikeMgr == none) // Prevent duplicate Managers
	{
		// Add the manager class
		StrikeMgr = XComGameState_SupportStrikeManager(NewGameState.CreateNewStateObject(class'XComGameState_SupportStrikeManager'));
		`LOG("[InitializeSupportStrikeManager()] Installing Support Strike Manager with Object ID: " $ StrikeMgr.ObjectID,Log(,true),'WotC_Gameplay_SupportStrikes');
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`LOG("[InitializeSupportStrikeManager()] SUCCESS... Installed Support Strike Manager.",Log(,true),'WotC_Gameplay_SupportStrikes');
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		`LOG("[InitializeSupportStrikeManager()] Support Strike Manager was already installed.",Log(,true),'WotC_Gameplay_SupportStrikes');
		History.CleanupPendingGameState(NewGameState);
	}
}


/*
static function AddItemsToHQ()
{
	local XComGameStateHistory					History;
	local XComGameState							NewGameState;
	local X2ItemTemplate						ItemTemplate;
	local X2ItemTemplateManager					ItemManager;
	local XComGameState_HeadquartersXCom		XComHQ;
	local XComGameState_Item					NewItemState;
	local name									ItemName;
	local int									i;

    History = `XCOMHISTORY;
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("WotC_Gameplay_SupportStrikes: Give Items");
    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
    NewGameState.AddStateObject(XComHQ);
    ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	//If the research is already completed, create itemstates and add it to the HQ Inventory
	if (IsResearchInHistory('AutopsyAdventTrooper'))
	{
		foreach default.ItemsToAdd(ItemName)
		{
			ItemTemplate = ItemManager.FindItemTemplate(ItemName);
			if (XComHQ.HasItem(ItemTemplate))
			{
				NewItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
				NewGameState.AddStateObject(NewItemState);
				XComHQ.AddItemToHQInventory(NewItemState);	
			}
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}
*/

//Helper function from RealityMachina's MOCX Initiative mod
static function bool IsResearchInHistory(name ResearchName)
{
	// Check if we've already injected the tech templates
	local XComGameState_Tech	TechState;
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if ( TechState.GetMyTemplateName() == ResearchName )
		{
			return true;
		}
	}
	return false;
}

//start Issue #112
/// <summary>
/// Called from XComGameState_HeadquartersXCom
/// lets mods add their own events to the event queue when the player is at the Avenger or the Geoscape
/// </summary>

/*
static function bool GetDLCEventInfo(out array<HQEvent> arrEvents)
{
	GetSupportStrikeHQEvents(arrEvents);
	return true; //returning true will tell the game to add the events have been added to the above array
}

static function GetSupportStrikeHQEvents(out array<HQEvent> arrEvents)
{
	local string												AbilityNameStr, GeneModdingStr;
	local HQEvent												kEvent;
	local XComGameState_HeadquartersProjectGeneModOperation		GeneProject;
	local XComGameState_Unit									UnitState;
	local XComGameStateHistory									History;

	History = `XCOMHISTORY;
	GeneProject = GetGeneModProjectFromHQ();
	
	if (GeneProject != none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(GeneProject.ProjectFocus.ObjectID));
		//This should never happen, but if it does, do nothing
		if (UnitState != none)
		{
			//Create HQ Event
			AbilityNameStr = Caps(GeneProject.GetMyTemplate().GetDisplayName());
			GeneModdingStr = Repl(default.GeneModEventLabel, "%CLASSNAME", AbilityNameStr);
			
			kEvent.Data = GeneModdingStr @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = GeneProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Science;
			arrEvents.AddItem(kEvent);
		}
	}
}
*/

/// Start Issue #419
/// <summary>
/// Called from X2AbilityTag.ExpandHandler
/// Expands vanilla AbilityTagExpandHandler to allow reflection
/// </summary>

static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseOb, XComGameState GameState)
{
	local XComGameState_Ability					AbilityState;
	local name									Type;
	local X2SupportStrikeUnlockTemplate			GTSUnlockTemplate;

	Type = name(InString);

	switch (Type)
	{
		case 'STRIKE_INTELCOST_USAGE_DYN':
			OutString = "";
			AbilityState = XComGameState_Ability(ParseObj);
			if (AbilityState != none)
			{
				BuildDynamicIntelCost(OutString, AbilityState.GetMyTemplateName(), true);
				return true;
			}
			
			GTSUnlockTemplate = X2SupportStrikeUnlockTemplate(ParseObj);
			if (GTSUnlockTemplate != none)
			{
				BuildDynamicIntelCost(OutString, GTSUnlockTemplate.AbilityName, true);
				return true;
			}
			break;	
	}
	return false;
}

// Function that dynamicially builds the Intel cost string: "[12, 345, 6789]", bHighlightCurrentUsage highlights the current usage of the month
static function BuildDynamicIntelCost(out string strDescription, name TemplateName, bool bHighlightCurrentUsage)
{	
	local XComGameStateHistory					History;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;
	local int									Idx, i;

	History = `XCOMHISTORY;
	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	strDescription = "[";
	Idx = SupportStrikeMgr.GetCurrentStrikeUsage(TemplateName);

	for (i = 0; i < SupportStrikeMgr.StrikeCurrentMonthUsage[Idx].MaximumCap; ++i)
	{
		if ((i == SupportStrikeMgr.StrikeCurrentMonthUsage[Idx].Usage) && bHighlightCurrentUsage)
			strDescription $= "<font color='#27aae1'><b>" $ string(SupportStrikeMgr.CalculateStrikeCost_Simple(TemplateName,, i, 0)) $ "</b></font>";
		else
			strDescription $= string(SupportStrikeMgr.CalculateStrikeCost_Simple(TemplateName,, i, 0));

		//If we aren't on the second to last, or last iterator, make a comma
		if (i < (SupportStrikeMgr.StrikeCurrentMonthUsage[Idx].MaximumCap - 1))
			strDescription $= ", ";
	}
	
	strDescription $= "]";
}