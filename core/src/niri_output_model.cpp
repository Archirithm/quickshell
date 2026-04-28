#include "niri_output_model.h"

NiriOutputModel::NiriOutputModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int NiriOutputModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_outputs.count();
}

QVariant NiriOutputModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_outputs.count())
        return {};

    const NiriOutput &output = m_outputs.at(index.row());
    switch (role) {
    case NameRole:
        return output.name;
    case MakeRole:
        return output.make;
    case ModelRole:
        return output.model;
    case SerialRole:
        return output.serial;
    case LogicalXRole:
        return output.logicalX;
    case LogicalYRole:
        return output.logicalY;
    case LogicalWidthRole:
        return output.logicalWidth;
    case LogicalHeightRole:
        return output.logicalHeight;
    case ScaleRole:
        return output.scale;
    case TransformRole:
        return output.transform;
    case CurrentModeRole:
        return output.currentMode;
    case VrrEnabledRole:
        return output.vrrEnabled;
    default:
        return {};
    }
}

QHash<int, QByteArray> NiriOutputModel::roleNames() const
{
    return {
        {NameRole, "name"},
        {MakeRole, "make"},
        {ModelRole, "model"},
        {SerialRole, "serial"},
        {LogicalXRole, "logicalX"},
        {LogicalYRole, "logicalY"},
        {LogicalWidthRole, "logicalWidth"},
        {LogicalHeightRole, "logicalHeight"},
        {ScaleRole, "scale"},
        {TransformRole, "transform"},
        {CurrentModeRole, "currentMode"},
        {VrrEnabledRole, "vrrEnabled"},
    };
}

void NiriOutputModel::setOutputs(const QList<NiriOutput> &outputs)
{
    beginResetModel();
    const int oldCount = m_outputs.count();
    m_outputs = outputs;
    endResetModel();
    if (oldCount != m_outputs.count())
        emit countChanged();
}

const QList<NiriOutput> &NiriOutputModel::outputs() const
{
    return m_outputs;
}

QVariantMap NiriOutputModel::outputByName(const QString &name) const
{
    for (const NiriOutput &output : m_outputs) {
        if (output.name == name)
            return toMap(output);
    }
    return {};
}

QVariantMap NiriOutputModel::toMap(const NiriOutput &output) const
{
    return {
        {QStringLiteral("name"), output.name},
        {QStringLiteral("make"), output.make},
        {QStringLiteral("model"), output.model},
        {QStringLiteral("serial"), output.serial},
        {QStringLiteral("logicalX"), output.logicalX},
        {QStringLiteral("logicalY"), output.logicalY},
        {QStringLiteral("logicalWidth"), output.logicalWidth},
        {QStringLiteral("logicalHeight"), output.logicalHeight},
        {QStringLiteral("scale"), output.scale},
        {QStringLiteral("transform"), output.transform},
        {QStringLiteral("currentMode"), output.currentMode},
        {QStringLiteral("vrrEnabled"), output.vrrEnabled},
    };
}
