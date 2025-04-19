import { useState } from 'react';
import { sendAct, useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Collapsible,
  Divider,
  Dropdown,
  Input,
  LabeledList,
  NumberInput,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { GameIcon } from '../components/GameIcon';
import { Window } from '../layouts';

interface StorageNodeInterface {
  dosh: number;
  authorization: BooleanLike;
  accountname: string;
  accountnum: number;
  budget: number;
  matnums: number[];
  matnames: string[];
  maticons: string[];
  matvalues: number[];
  sellthreshold: number;
  portmatvalues: number[];
  portmatamounts: number[];
  portmaticons: string[];
  portmatnames: string[];
  idnums: number[];
  iddescs: string[];
  IDcodereq: number;
  otherprimeloc: string;
}

const exchange = (props) => {
  const { matnames, matnums, matvalues, dosh, maticons } = props;
  const [selection, setSelection] = useState(-1);
  const [amt, setAmt] = useState<number>(0);
  const act = sendAct;
  return (
    <>
      {maticons.map((mapped, count: number) => {
        return displayfourstats(
          matnames[count],
          matnums[count],
          matvalues[count],
          maticons[count],
        );
      })}
      <Dropdown
        options={matnames}
        onSelected={(value) => setSelection(matnames.indexOf(value))}
        selected={selection !== -1 ? matnames[selection] : ''}
      />
      <NumberInput
        value={amt}
        maxValue={selection !== -1 ? matnums[matnames.indexOf(selection)] : 0}
        onChange={(value: number) => setAmt(value)}
        minValue={0}
        step={1}
      />
      {selection !== -1 && 'price of selection:'}
      {selection !== -1 && amt * matvalues[selection]}
      {selection !== -1 && (
        <Button
          onClick={() => {
            setAmt(0);
            setSelection(-1);
            act('buymat', { matselected: selection + 1, amount: amt });
          }}
        >
          Buy Selected
        </Button>
      )}
      <Divider hidden />
      {dosh && 'Card:'}
      {dosh}
      {dosh !== null && (
        <Button content="Logout" onClick={() => act('logout')} />
      )}
    </>
  );
};

const sale = (props) => {
  const act = sendAct;
  const {
    budget,
    dosh,
    portmatnames,
    portmatamounts,
    portmaticons,
    portmatvalues,
  } = props;
  const [selection, setSelection] = useState<number>(-1);
  return (
    <>
      <LabeledList.Item label="Budget">{budget}</LabeledList.Item>
      <LabeledList>
        <LabeledList.Item label="Material Input">
          {portmatnames !== null && (
            <Dropdown
              options={portmatnames}
              onSelected={(value) => setSelection(portmatnames.indexOf(value))}
              selected={selection !== -1 ? portmatnames[selection] : ''}
            />
          )}
          {portmatnames !== null && (
            <Button
              onClick={() => {
                setSelection(-1);
                act('eject');
              }}
            >
              Eject Mats
            </Button>
          )}
          {portmatnames !== null && (
            <Button
              onClick={() => {
                setSelection(-1);
                act('sellmat');
              }}
            >
              Sell Mats
            </Button>
          )}

          {portmaticons &&
            portmaticons.map((mapped, count: number) => {
              return displayfourstats(
                portmatnames[count],
                portmatamounts[count],
                portmatvalues[count],
                portmaticons[count],
              );
            })}

          {selection !== -1 && (
            <Button
              onClick={() => {
                setSelection(-1);
                act('eject', { selected: selection + 1 });
              }}
            >
              Eject Selected
            </Button>
          )}

          {selection !== -1 && (
            <Button
              onClick={() => {
                setSelection(-1);
                act('sellmat', { selected: selection + 1 });
              }}
            >
              Sell Selected
            </Button>
          )}
        </LabeledList.Item>
      </LabeledList>
      <Box>
        {dosh && 'Card:'}
        {dosh}
        {dosh !== null && (
          <Button content="Logout" onClick={() => act('logout')} />
        )}
      </Box>
    </>
  );
};

const displayfourstats = (name, _number, value, icon) => {
  return (
    <Box inline>
      {icon && <GameIcon html={icon} className="game-icon" />}
      <Divider hidden />
      {name}
      {' available: '}
      {_number}
      <Divider hidden />
      {'price per unit '}
      {/* context doesn't exist anymore so i dont know what to do with this - Chen */}
      {/* {context ? value * 0.9 : value * 1.1} */}
      {value}
    </Box>
  );
};

const administration = (props) => {
  const {
    budget,
    authorization,
    sellthreshold,
    accountname,
    accountnum,
    idnums,
    iddescs,
    IDcodereq,
  } = props;
  const act = sendAct;
  const [newbudget, setBudget] = useState<number>(budget);
  const [newthreshold, setThreshold] = useState<number>(sellthreshold);
  const [newaccount, setAccount] = useState<number>(accountnum);
  return (
    <>
      <LabeledList.Item label="Current Budget">{budget}</LabeledList.Item>
      {authorization && (
        <LabeledList.Item label="Maximum Budget">
          <NumberInput
            value={newbudget}
            onChange={(value: number) => setBudget(value)}
            minValue={0}
            maxValue={10000}
            step={10}
          />
          {authorization && (
            <Button
              content="Set Maximum Budget"
              onClick={() => act('setbudget', { newbudget: newbudget })}
            />
          )}
        </LabeledList.Item>
      )}
      {
        <LabeledList.Item label="Current Sale Threshold">
          {sellthreshold}
        </LabeledList.Item>
      }
      {authorization && (
        <LabeledList.Item label="Maximum Sale Threshold">
          <NumberInput
            value={newthreshold}
            onChange={(value: number) => setThreshold(value)}
            minValue={0}
            maxValue={10000}
            step={10}
          />
        </LabeledList.Item>
      )}
      {authorization && (
        <Button
          onClick={() => act('setthreshold', { newthreshold: newthreshold })}
        >
          Set Maximum Sale Threshold
        </Button>
      )}
      {<LabeledList.Item label="Account">{accountname}</LabeledList.Item>}
      {authorization && (
        <Input
          value={newaccount}
          onInput={(e, value: string) => {
            if (Number.isInteger(Number(value))) {
              setAccount(Number(value));
            }
          }}
        />
      )}
      {authorization && (
        <Button onClick={() => act('setaccount', { newID: newaccount })}>
          Set Account ID
        </Button>
      )}
      {authorization && (
        <Collapsible title="Set Required Access Code">
          {idnums.map((mapped, count: number) => (
            <Button
              content={iddescs[count]}
              selected={IDcodereq === mapped}
              onClick={() => act('setID', { newID: mapped })}
              key={mapped}
            />
          ))}
        </Collapsible>
      )}
    </>
  );
};

export const StorageNode = (props) => {
  const { act, data } = useBackend<StorageNodeInterface>();
  const {
    dosh,
    budget,
    authorization,
    accountname,
    accountnum,
    matnums,
    matnames,
    maticons,
    matvalues,
    sellthreshold,
    portmatvalues,
    portmatamounts,
    portmaticons,
    portmatnames,
    idnums,
    iddescs,
    IDcodereq,
    otherprimeloc,
  } = data;
  const [menu, setMenu] = useState<string>(
    portmatnames !== null
      ? 'sale'
      : authorization
        ? 'administration'
        : 'materialexchange',
  );
  return (
    <Window>
      <Window.Content scrollable>
        {(otherprimeloc && (
          <>
            {'Location of Prime Silo:'}
            {otherprimeloc}
            <Divider hidden />
            <Button onClick={() => act('resetprime')}>
              Reset Prime status
            </Button>
          </>
        )) || (
          <>
            <Button
              disabled={authorization ? false : true}
              selected={menu === 'administration'}
              onClick={() => setMenu('administration')}
            >
              Administration
            </Button>
            <Button selected={menu === 'sale'} onClick={() => setMenu('sale')}>
              Input
            </Button>
            <Button
              selected={menu === 'materialexchange'}
              onClick={() => setMenu('materialexchange')}
            >
              Exchange
            </Button>
            <Divider />
            {menu === 'administration' &&
              authorization &&
              administration({
                budget,
                authorization,
                sellthreshold,
                accountname,
                accountnum,
                idnums,
                iddescs,
                IDcodereq,
              })}
            {menu === 'sale' &&
              sale({
                budget,
                dosh,
                portmatnames,
                portmatamounts,
                portmaticons,
                portmatvalues,
              })}
            {menu === 'materialexchange' &&
              exchange({ matnames, matnums, matvalues, dosh, maticons })}
          </>
        )}
      </Window.Content>
    </Window>
  );
};
