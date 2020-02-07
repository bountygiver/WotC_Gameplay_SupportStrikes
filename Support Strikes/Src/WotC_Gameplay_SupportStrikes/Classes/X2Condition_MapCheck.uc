//
// AUTHOR:	E3245
// DESC:	Checks current XCGS_BattleData and sees if a particular biome, plot, or parcel is loaded.
//			Fails if the current XCGS_BattleData contains any one of them.

class X2Condition_MapCheck extends X2Condition config (GameData);

var config array<string> DisallowedBiomes;
var config array<string> DisallowedPlots;
var config array<string> DisallowedParcels;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_BattleData BattleData;
	local PlotDefinition PlotDef;
	local string PlotType;
	local StoredMapData_Parcel ParcelComp;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	PlotDef = `PARCELMGR.GetPlotDefinition(BattleData.MapData.PlotMapName);
	PlotType = PlotDef.strType;

	`LOG("[X2Condition_MapCheck::CallMeetsCondition()] Count: Disallowed Biomes: "$ DisallowedBiomes.Length $", Disallowed Plots: "$ DisallowedPlots.Length $", Disallowed Parcels: "$ DisallowedParcels.Length ,,'WotC_Gameplay_SupportStrikes');
	`LOG("[X2Condition_MapCheck::CallMeetsCondition()] Biome: " $ BattleData.MapData.Biome,,'WotC_Gameplay_SupportStrikes');
	`LOG("[X2Condition_MapCheck::CallMeetsCondition()] Plot Type: " $ PlotType ,,'WotC_Gameplay_SupportStrikes');

	if (DisallowedBiomes.Length > 0)
		if (DisallowedBiomes.Find(BattleData.MapData.Biome) != INDEX_NONE)
			return 'AA_MustBeOutdoors';

	if (DisallowedPlots.Length > 0)
		if (DisallowedPlots.Find(PlotType) != INDEX_NONE)
			return 'AA_MustBeOutdoors';

	if (DisallowedParcels.Length > 0)
		foreach BattleData.MapData.ParcelData(ParcelComp)
			if (DisallowedParcels.Find(ParcelComp.MapName) != INDEX_NONE)
				return 'AA_MustBeOutdoors';

	`LOG("[X2Condition_MapCheck::CallMeetsCondition()] Condition Passed",,'WotC_Gameplay_SupportStrikes');

	return 'AA_Success';
}