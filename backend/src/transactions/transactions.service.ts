import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { TransactionRecord, TransactionRecordDocument } from './schemas/transaction.schema';

@Injectable()
export class TransactionsService {
  constructor(
    @InjectModel(TransactionRecord.name)
    private readonly transactionModel: Model<TransactionRecordDocument>,
  ) {}

  create(dto: CreateTransactionDto) {
    return this.transactionModel.create(dto);
  }

  findByUserEmail(userEmail: string) {
    const normalizedEmail = userEmail.trim().toLowerCase();
    if (!normalizedEmail) {
      return [];
    }

    return this.transactionModel
      .find({
        $or: [
          { buyerEmail: normalizedEmail },
          { sellerEmail: normalizedEmail },
        ],
      })
      .sort({ createdAt: -1 })
      .exec();
  }
}
