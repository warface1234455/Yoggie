import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, Chart, Flex, ProgressBar, Section, Tabs, Slider } from '../components';
import { FlexItem } from '../components/Flex';
import { formatSiUnit } from '../format';

export const RbmkComputer = (props, context) => {
  const [tabIndex, setTabIndex] = useLocalState(context, "tab-index", 1);
  return (
    <Window
      resizable
      width={360}
      height={540}>
      <Window.Content fitted>
        <Tabs>
          <Tabs.Tab
            selected={tabIndex === 1}
            onClick={() => setTabIndex(1)}>
            Status
          </Tabs.Tab>
          <Tabs.Tab
            selected={tabIndex === 2}
            onClick={() => setTabIndex(2)}>
            Control Rods
          </Tabs.Tab>
          <Tabs.Tab
            selected={tabIndex === 3}
            onClick={() => setTabIndex(3)}>
            Fuel Rods
          </Tabs.Tab>
        </Tabs>
        {tabIndex === 1 && <RbmkStatsSection />}
        {tabIndex === 2 && <RbmkControlRodControl />}
        {tabIndex === 3 && <RbmkFuelControl />}
      </Window.Content>
    </Window>
  );
};

export const RbmkStatsSection = (props, context) => {
  const { act, data } = useBackend(context);
  const powerData = data.powerData.map((value, i) => [i, value]);
  const kpaData = data.kpaData.map((value, i) => [i, value]);
  const tempCoreData = data.tempCoreData.map((value, i) => [i, value]);
  const tempInputData = data.tempInputData.map((value, i) => [i, value]);
  const tempOutputData = data.tempOutputData.map((value, i) => [i, value]);
  return (
    <Box height="100%">
      <Section title="Legend:">
        Reactor Power:
        <ProgressBar
          value={data.power}
          minValue={0}
          maxValue={10000000}
          color="yellow">
          {formatSiUnit(data.power, 0, "W")}
        </ProgressBar>
        Reactor Pressure:
        <ProgressBar
          value={data.kpa}
          minValue={0}
          maxValue={10000}
          color="white" >
          {formatSiUnit(data.kpa*1000, 1, "Pa")}
        </ProgressBar>
        Core temperature:
        <ProgressBar
          value={data.coreTemp}
          minValue={0}
          maxValue={1500}
          color="orange">
          {data.coreTemp} K
        </ProgressBar>
        Coolant temperature:
        <ProgressBar
          value={data.coolantInput}
          minValue={0}
          maxValue={1500}
          color="blue">
          {data.coolantInput} K
        </ProgressBar>
        Outlet temperature:
        <ProgressBar
          value={data.coolantOutput}
          minValue={0}
          maxValue={1500}
          color="bad">
          {data.coolantOutput} K
        </ProgressBar>
        Neutrons per generation (K):
        <ProgressBar
          value={data.k / 5}
          ranges={{
            good: [-Infinity, 0.4],
            average: [0.4, 0.6],
            bad: [0.6, Infinity],
          }}>
          {data.k}
        </ProgressBar>
      </Section>
      <Section fill title="Reactor Statistics:" height="200px">
        <Chart.Line
          fillPositionedParent
          data={powerData}
          rangeX={[0, powerData.length - 1]}
          rangeY={[0, Math.max(15000000, ...data.powerData)]}
          strokeColor="rgba(255, 215,0, 1)"
          fillColor="rgba(255, 215, 0, 0.1)" />
        <Chart.Line
          fillPositionedParent
          data={kpaData}
          rangeX={[0, kpaData.length - 1]}
          rangeY={[0, Math.max(10000, ...data.kpaData)]}
          strokeColor="rgba(255,250,250, 1)"
          fillColor="rgba(255,250,250, 0.1)" />
        <Chart.Line
          fillPositionedParent
          data={tempCoreData}
          rangeX={[0, tempCoreData.length - 1]}
          rangeY={[0, Math.max(1800, ...data.tempCoreData)]}
          strokeColor="rgba(255, 129, 25 , 1)"
          fillColor="rgba(255, 129, 25 , 0.1)" />
        <Chart.Line
          fillPositionedParent
          data={tempInputData}
          rangeX={[0, tempInputData.length - 1]}
          rangeY={[0, Math.max(1800, ...data.tempInputData)]}
          strokeColor="rgba(127, 179, 255 , 1)"
          fillColor="rgba(127, 179, 255 , 0.1)" />
        <Chart.Line
          fillPositionedParent
          data={tempOutputData}
          rangeX={[0, tempOutputData.length - 1]}
          rangeY={[0, Math.max(1800, ...data.tempOutputData)]}
          strokeColor="rgba(255, 0, 0 , 1)"
          fillColor="rgba(255, 0, 0 , 0.1)" />
      </Section>
    </Box>
  );
};

export const RbmkControlRodControl = (props, context) => {
  const { act, data } = useBackend(context);
  const control_rods = data.control_rods;
  const k = data.k;
  const desiredK = data.desiredK;
  return (
    <Section title="Control Rod Management:" height="100%">
      Control Rod Insertion:
      <ProgressBar
        value={(control_rods / 100 * 100) * 0.01}
        ranges={{
          good: [0.7, Infinity],
          average: [0.4, 0.7],
          bad: [-Infinity, 0.4],
        }} />
      <br />
      Neutrons per generation (K):
      <br />
      <ProgressBar
        value={(k / 5 * 100) * 0.01}
        ranges={{
          good: [-Infinity, 0.4],
          average: [0.4, 0.6],
          bad: [0.6, Infinity],
        }}>
        {k}
      </ProgressBar>
      <br />
      Target criticality:
      <br />
      <Slider
        value={Math.round(desiredK*10)/10}
        fillValue={Math.round(k*10)/10}
        minValue={0}
        maxValue={5}
        step={0.1}
        stepPixelSize={5}
        onDrag={(e, value) => act('input', {
          target: value,
        })} />
    </Section>
  );
};

export const RbmkFuelControl = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Section title="Fuel Rod Management" height="100%">
      {!data.rods.length ? (
        <Box>
          <Flex direction="column">
            {Object.keys(data.rods).map(rod => (
              <FlexItem key={rod}>
                <Box inline mr={"3rem"} my={"0.5rem"}>
                  {data.rods[rod].name}
                </Box>
                <Button
                  inline
                  icon={'times'}
                  content={'Eject'}
                  disabled={data.power >= 20}
                  onClick={() => act('eject', {
                    rodRef: rod,
                  })} />
                <ProgressBar
                  value={100-data.rods[rod].depletion}
                  minValue={0}
                  maxValue={100}
                  ranges={{
                    good: [75, Infinity],
                    average: [40, 75],
                    bad: [-Infinity, 40],
                  }}
                />
              </FlexItem>
            ))}
          </Flex>
        </Box>
      ) : (
        <Box fontSize={3}>
          No Rods Found
        </Box>
      )}
    </Section>
  );
};
